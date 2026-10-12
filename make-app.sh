#!/bin/zsh
# Builds "SvR 2011.app": a small macOS app that opens the port's launcher in a CrossOver bottle.
# usage: make-app.sh <game folder> [bottle name] [destination folder]
set -euo pipefail

GAME=${1:?usage: make-app.sh <game folder> [bottle] [destination]}
BOTTLE=${2:-SVR2011}
DEST=${3:-$HOME/Applications}
HERE=${0:A:h}
WINE=/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine
APP="$DEST/SvR 2011.app"

GAME=${GAME:A}
[[ -f "$GAME/SvR2011 Launcher.exe" ]] || { echo "no 'SvR2011 Launcher.exe' in $GAME" >&2; exit 1; }
[[ -x $WINE ]] || { echo "CrossOver not found in /Applications" >&2; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/MacOS/launch" <<EOF
#!/bin/zsh
exec "$WINE" --bottle "$BOTTLE" --workdir "$GAME" "$GAME/SvR2011 Launcher.exe"
EOF
chmod +x "$APP/Contents/MacOS/launch"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>SvR 2011</string>
	<key>CFBundleDisplayName</key><string>SvR 2011</string>
	<key>CFBundleIdentifier</key><string>local.svr2011.launcher</string>
	<key>CFBundleExecutable</key><string>launch</string>
	<key>CFBundleIconFile</key><string>icon</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleVersion</key><string>1.0</string>
	<key>LSApplicationCategoryType</key><string>public.app-category.sports-games</string>
</dict>
</plist>
EOF

# icon from the launcher's own .exe
TMP=$(mktemp -d)
python3 -I "$HERE/extract_icon.py" "$GAME/SvR2011 Launcher.exe" "$TMP/icon.ico" >/dev/null
sips -s format png "$TMP/icon.ico" --out "$TMP/icon.png" >/dev/null
sips -s format icns "$TMP/icon.png" --out "$APP/Contents/Resources/icon.icns" >/dev/null
rm -rf "$TMP"

touch "$APP"  # refresh Finder's icon cache
echo "created $APP"
