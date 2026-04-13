from flask import Flask, request, send_file, jsonify, send_from_directory
import os, subprocess, uuid

BASE = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE, "uploads")
OUTPUT_DIR = os.path.join(BASE, "outputs")
LUT_DIR = os.path.join(BASE, "luts")
SCRIPT = os.path.join(BASE, "apply_lut.sh")

app = Flask(__name__, static_folder="static")

@app.route("/")
def index():
    return send_from_directory("static", "index.html")

@app.get("/luts")
def list_luts():
    out = []
    for root, _, files in os.walk(LUT_DIR):
        for f in files:
            if f.lower().endswith(".cube"):
                rel = os.path.relpath(os.path.join(root, f), LUT_DIR)
                out.append(rel)
    return jsonify({"luts": sorted(out)})

@app.post("/process")
def process():
    if "image" not in request.files:
        return jsonify({"error": "No image file uploaded"}), 400

    lut_rel = (request.form.get("lut") or "").replace("\\", "/")
    if not lut_rel:
        return jsonify({"error": "No LUT selected"}), 400

    # Intensity from form (0..1)
    intensity = request.form.get("intensity", "1")
    try:
        t = float(intensity)
        if t < 0: t = 0.0
        if t > 1: t = 1.0
        intensity = str(t)
    except Exception:
        intensity = "1"

    # NEW: optional tags (comma-separated); empty string if not provided
    tags = (request.form.get("tags") or "").strip()  # NEW

    # Resolve LUT path safely
    lut_path = os.path.abspath(os.path.join(LUT_DIR, lut_rel))
    lut_root = os.path.abspath(LUT_DIR)
    if not lut_path.startswith(lut_root + os.sep) or not os.path.isfile(lut_path):
        return jsonify({"error": f"LUT not found: {lut_rel}"}), 400

    # Ensure dirs exist (NEW)
    os.makedirs(UPLOAD_DIR, exist_ok=True)           # NEW
    os.makedirs(OUTPUT_DIR, exist_ok=True)           # NEW

    img = request.files["image"]
    ext = os.path.splitext(img.filename or "")[1].lower() or ".jpg"
    uid = uuid.uuid4().hex
    in_path = os.path.join(UPLOAD_DIR, f"in_{uid}{ext}")
    out_path = os.path.join(OUTPUT_DIR, f"out_{uid}{ext}")
    img.save(in_path)

    # Call script with 5 args: input, lut, output, intensity, tags
    try:
        subprocess.run([SCRIPT, in_path, lut_path, out_path, intensity, tags], check=True)
    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"Processing failed: {e}"}), 500

    return send_file(out_path, as_attachment=False)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=True)

