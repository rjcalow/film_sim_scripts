# Film Sim Scripts

Apply .cube LUTs to JPEG images using G'MIC — either from the Thunar file browser
via a right-click action, or through a local web interface.

## Dependencies

    sudo apt install gmic yad
    pip install flask        # only needed for the web server

## Files

    apply_lut.sh             Core script — applies a LUT to a single image
    thunar_apply_lut.sh      Thunar right-click action (GUI picker + intensity slider)
    install_thunar_action.sh Installs the Thunar custom action
    server.py                Optional local web interface
    film_canister.svg        Dialog icon

## Thunar Integration (recommended)

1. Drop your .cube LUT files into the luts/ folder
2. Run the installer once:

    bash install_thunar_action.sh

3. Right-click any JPEG in Thunar → "Apply Film LUT"
4. Pick a LUT from the scrollable list, set intensity with the slider, click Apply

Output is saved next to the original file:
    photo.jpg + Analog/A10_64.cube → photo_A10_64.jpg

## Command Line

    ./apply_lut.sh <input.jpg> <lut.cube> <output.jpg> [intensity 0-1] [tags]

    intensity defaults to 1.0 (full strength)
    tags are written to EXIF/IPTC metadata (requires exiftool)

## Web Interface (optional)

    python3 server.py

Then open http://127.0.0.1:8000/

## Notes

- LUTs are not included in the repository — add your own .cube files to luts/
- exiftool is optional; if present, LUT name and intensity are written to image metadata
