#!/usr/bin/env bash
# install_thunar_action.sh — add "Apply Film LUT" to Thunar's right-click menu
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
THUNAR_SCRIPT="$SCRIPT_DIR/thunar_apply_lut.sh"
UCA_FILE="$HOME/.config/Thunar/uca.xml"
ACTION_ID="film-sim-apply-lut-001"

# Ensure the script is executable
chmod +x "$THUNAR_SCRIPT"
chmod +x "$SCRIPT_DIR/apply_lut.sh"

if [ ! -f "$UCA_FILE" ]; then
  echo "Thunar custom actions file not found: $UCA_FILE"
  echo "Is Thunar installed? Run it once to create the config file."
  exit 1
fi

# Skip if already installed
if grep -q "$ACTION_ID" "$UCA_FILE"; then
  echo "Action already installed (id: $ACTION_ID). Nothing to do."
  exit 0
fi

# Back up
cp "$UCA_FILE" "${UCA_FILE}.bak"
echo "Backed up uca.xml → ${UCA_FILE}.bak"

# Inject action before closing </actions> tag
NEW_ACTION="<action>
\t<icon>image-x-generic</icon>
\t<name>Apply Film LUT</name>
\t<submenu></submenu>
\t<unique-id>$ACTION_ID</unique-id>
\t<command>$THUNAR_SCRIPT %F</command>
\t<description>Apply a .cube LUT to selected JPEG(s) via G'MIC</description>
\t<range></range>
\t<patterns>*.jpg;*.jpeg;*.JPG;*.JPEG</patterns>
\t<image-files/>
</action>"

# Use python to safely insert XML rather than fragile sed
python3 - "$UCA_FILE" "$NEW_ACTION" <<'PYEOF'
import sys, re

uca_path = sys.argv[1]
new_action = sys.argv[2]

with open(uca_path, 'r') as f:
    content = f.read()

# Insert before </actions>
content = content.rstrip()
if content.endswith('</actions>'):
    content = content[:-len('</actions>')] + new_action + '\n</actions>\n'
else:
    print("ERROR: could not find </actions> in uca.xml", file=sys.stderr)
    sys.exit(1)

with open(uca_path, 'w') as f:
    f.write(content)

print("Done.")
PYEOF

echo ""
echo "Installed! Right-click a JPG in Thunar and choose 'Apply Film LUT'."
echo "If Thunar is open, close and reopen it (or log out/in) for the action to appear."
