#!/usr/bin/env bash
# thunar_apply_lut.sh — Thunar custom action: pick a LUT via GUI and apply to selected JPG(s)
# Usage: thunar_apply_lut.sh <image1.jpg> [image2.jpg ...]
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LUT_DIR="$SCRIPT_DIR/luts"
APPLY_SCRIPT="$SCRIPT_DIR/apply_lut.sh"

if [ "$#" -eq 0 ]; then
  yad --error --title="Apply Film LUT" --text="No files provided."
  exit 1
fi

# Collect relative LUT names for display
mapfile -t LUT_RELS < <(
  find "$LUT_DIR" -name "*.cube" -printf "%P\n" | sort
)

if [ "${#LUT_RELS[@]}" -eq 0 ]; then
  yad --error --title="Apply Film LUT" \
    --text="No .cube LUT files found in:\n$LUT_DIR"
  exit 1
fi

KEY=$RANDOM
TMP_LUT=$(mktemp)
TMP_INT=$(mktemp)

# Pane 1 (top): scrollable LUT list — outputs selected row on activation
printf '%s\n' "${LUT_RELS[@]}" | \
  yad --plug="$KEY" --tabnum=1 \
      --list --no-headers \
      --column="Select LUT" \
      --no-buttons \
      --print-column=1 \
      2>/dev/null > "$TMP_LUT" &
LIST_PID=$!

# Pane 2 (bottom): intensity slider
yad --plug="$KEY" --tabnum=2 \
    --form \
    --field="Intensity %:SCL" "100" \
    --no-buttons \
    2>/dev/null > "$TMP_INT" &
FORM_PID=$!

# Container window with OK/Cancel
# --splitter sets the divider position in px from top (list height)
yad --paned --key="$KEY" \
    --orient=vertical \
    --title="Apply Film LUT" \
    --window-icon="$SCRIPT_DIR/film_canister.svg" \
    --button="Apply!gtk-ok:0" \
    --button="Cancel!gtk-cancel:1" \
    --width=460 --height=520 \
    --splitter=430 \
    2>/dev/null
PANED_EXIT=$?

wait $LIST_PID $FORM_PID 2>/dev/null || true

if [ $PANED_EXIT -ne 0 ]; then
  rm -f "$TMP_LUT" "$TMP_INT"
  exit 0
fi

# yad list outputs "value|" per row; grab last selected line, strip trailing pipes
SELECTED_REL=$(tail -1 "$TMP_LUT" | tr -d '\n' | sed 's/|*$//')
[ -z "$SELECTED_REL" ] && SELECTED_REL="${LUT_RELS[0]}"

# yad form outputs "value|"; strip trailing pipe
INTENSITY_PCT=$(tr -d '\n' < "$TMP_INT" | sed 's/|*$//')
[ -z "$INTENSITY_PCT" ] && INTENSITY_PCT=100

rm -f "$TMP_LUT" "$TMP_INT"

LUT_PATH="$LUT_DIR/$SELECTED_REL"

if [ ! -f "$LUT_PATH" ]; then
  yad --error --title="Apply Film LUT" --text="LUT file not found:\n$LUT_PATH"
  exit 1
fi

LUT_LABEL="$(basename "$SELECTED_REL" .cube)"
LUT_LABEL="${LUT_LABEL:0:10}"

INTENSITY="$(awk -v p="$INTENSITY_PCT" 'BEGIN{ printf "%.2f", p/100 }')"

for INPUT in "$@"; do
  case "${INPUT,,}" in *.jpg|*.jpeg) ;; *) continue ;; esac
  [ -f "$INPUT" ] || continue

  DIR="$(dirname "$INPUT")"
  STEM="$(basename "$INPUT")"
  STEM="${STEM%.*}"
  EXT="${INPUT##*.}"

  "$APPLY_SCRIPT" "$INPUT" "$LUT_PATH" "$DIR/${STEM}_${LUT_LABEL}.${EXT}" "$INTENSITY" || true
done
