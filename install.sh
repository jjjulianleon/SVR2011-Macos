#!/bin/zsh
# Installs the WWE SmackDown vs. Raw 2011 PC port (github.com/KaikoClanworth1/wwe-svr2011-pc)
# on macOS with CrossOver, from your own Xbox 360 disc image.
#
# usage: ./install.sh <disc.iso> [game folder] [--bottle NAME] [--enable-mods]
#   game folder   where the game goes (default: ~/Games/SvR2011)
#   --bottle      CrossOver bottle to create or reuse (default: SVR2011)
#   --enable-mods switch on the bundled superstar and arena mods
set -euo pipefail

UPSTREAM=KaikoClanworth1/wwe-svr2011-pc
CX=/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin
HERE=${0:A:h}
BOTTLE=SVR2011
ENABLE_MODS=0
args=()
while (( $# )); do
  case $1 in
    --bottle) BOTTLE=${2:?--bottle needs a name}; shift 2 ;;
    --enable-mods) ENABLE_MODS=1; shift ;;
    -h|--help) sed -n '2,9p' $0; exit 0 ;;
    *) args+=$1; shift ;;
  esac
done
ISO=${args[1]:-}
GAME=${args[2]:-$HOME/Games/SvR2011}

die() { print -u2 "error: $*"; exit 1; }
step() { print "\n==> $*"; }
winpath() { local p=${1:A}; print -r -- "Z:${p//\//\\}"; }  # CrossOver maps Z: to /

[[ -n $ISO ]] || die "pass your Xbox 360 disc image: ./install.sh <disc.iso> [game folder]"
[[ -f $ISO ]] || die "disc image not found: $ISO"
[[ -x $CX/wine ]] || die "CrossOver is not installed in /Applications (https://www.codeweavers.com/crossover)"
[[ $(uname -m) == arm64 ]] || print "warning: D3DMetal needs an Apple Silicon Mac; on Intel the game may not start."
for t in curl unzip python3; do command -v $t >/dev/null || die "$t is missing"; done
mkdir -p "$GAME"
GAME=${GAME:A}
[[ -z $(ls -A "$GAME") || -f "$GAME/svr2011.exe" ]] || die "$GAME is not empty and is not a game folder; pick an empty folder"
# the launcher is a Windows program: paths of 260+ characters crash it (MAX_PATH)
(( ${#$(winpath "$ISO")} < 200 )) || die "the disc image's path is too long for Windows programs; move it to e.g. ~/Downloads"
(( ${#$(winpath "$GAME")} < 120 )) || die "the game folder's path is too long; pick a shorter one"

step "CrossOver bottle '$BOTTLE' (Windows 10, D3DMetal, MSync)"
CONF="$HOME/Library/Application Support/CrossOver/Bottles/$BOTTLE/cxbottle.conf"
[[ -f $CONF ]] || $CX/cxbottle --bottle "$BOTTLE" --create --template win10_64 >/dev/null
[[ -f $CONF ]] || die "could not create the bottle"
sed -i '' '/^"CX_GRAPHICS_BACKEND"/d; /^"WINEMSYNC"/d' "$CONF"
sed -i '' '/^\[EnvironmentVariables\]/a\
"CX_GRAPHICS_BACKEND" = "d3dmetal"\
"WINEMSYNC" = "1"
' "$CONF"

step "Downloading the latest PC release from github.com/$UPSTREAM"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
URL=$(curl -fsSL "https://api.github.com/repos/$UPSTREAM/releases/latest" | python3 -I -c '
import json, sys
print(next(a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"].startswith("SvR2011-PC-")))')
print "    $URL"
curl -fL --progress-bar -o "$TMP/port.zip" "$URL"
unzip -q -o "$TMP/port.zip" -d "$GAME"

step "Installing the game files from your disc image (about 5.3 GB, a few minutes)"
"$CX/wine" --bottle "$BOTTLE" --workdir "$GAME" "$GAME/SvR2011 Launcher.exe" --install "$(winpath "$ISO")" "$(winpath "$GAME")" \
  || die "the launcher could not install from $ISO (is it an Xbox 360 disc image of the game?)"
[[ -f "$GAME/default.xex" ]] || die "install finished but default.xex is missing"

if [[ ! -f "$GAME/svr2011.toml" ]]; then
  step "Settings tuned for Apple Silicon (svr2011.toml)"
  cat > "$GAME/svr2011.toml" <<'EOF'
# WWE SmackDown vs. Raw 2011 - settings (the launcher rewrites this file)
gpu_plugin = "xenos"
native_renderer = "main"
input_backend = "xinput"
resolution = "720p"
resolution_scale = 1
fullscreen = false
vsync = true
mnk_mode = true
show_fps = true
frame_rate = 60
full_speed = true
native_aa = 1
native_2x_msaa = false
native_max_scale = 2
native_prepare_pipelines = true
process_priority = 1
EOF
fi

if (( ENABLE_MODS )); then
  step "Switching on the bundled superstar and arena mods"
  rm -f "$GAME"/Mods/{Superstars,Arenas}/*/disabled(N)
fi

step "Creating the app"
"$HERE/make-app.sh" "$GAME" "$BOTTLE"

print "\nDone. Open 'SvR 2011' from Launchpad or ~/Applications, then press Play."
