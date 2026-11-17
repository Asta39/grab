#!/bin/bash
# Builds grab-macos.dmg with a designed install window:
# the Pop background, Grab on the left, Applications on the right.
#
#   macos/dmg/make_dmg.sh build/macos/Build/Products/Release/Grab.app grab-macos.dmg
set -euo pipefail

APP="$1"
OUT="${2:-grab-macos.dmg}"
HERE="$(cd "$(dirname "$0")" && pwd)"
VOL="Grab"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Stage: the app, a link to Applications, and the hidden background.
mkdir -p "$WORK/stage/.background"
cp -R "$APP" "$WORK/stage/Grab.app"
ln -s /Applications "$WORK/stage/Applications"
cp "$HERE/background.tiff" "$WORK/stage/.background/background.tiff"

# A writable image to arrange the window in.
hdiutil detach "/Volumes/$VOL" -force >/dev/null 2>&1 || true
hdiutil create -srcfolder "$WORK/stage" -volname "$VOL" -fs HFS+ \
  -format UDRW -ov "$WORK/rw.dmg" >/dev/null
MOUNT="$(hdiutil attach -readwrite -noverify -noautoopen "$WORK/rw.dmg" |
  awk -F'\t' '/\/Volumes\// {print $NF; exit}')"

# Window: 660 x 400 content, no toolbar or sidebar, big icons on the pads.
osascript <<EOF
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 860, 548}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 112
    set text size of opts to 13
    set background picture of opts to file ".background:background.tiff"
    set position of item "Grab.app" of container window to {170, 196}
    set position of item "Applications" of container window to {490, 196}
    update without registering applications
    delay 1
    close
    open
    delay 1
    close
  end tell
end tell
EOF

# Make the window open by itself when the dmg is mounted.
bless --folder "$MOUNT" --openfolder "$MOUNT" 2>/dev/null || true
chmod -Rf go-w "$MOUNT" || true
sync
hdiutil detach "$MOUNT" >/dev/null || hdiutil detach "$MOUNT" -force >/dev/null

# Compress into the final, read-only image.
rm -f "$OUT"
hdiutil convert "$WORK/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$OUT" >/dev/null
echo "Built $OUT"
