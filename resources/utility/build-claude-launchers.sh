#!/bin/bash
#
# Build per-account launcher bundles for Claude.app.
#
# Each bundle is a thin wrapper: it execs `open -n` against the real
# Claude.app with two isolating settings injected.
#
#   CLAUDE_CONFIG_DIR -> ~/.claude/<slug>/claude-code
#       Claude Code surface: CLAUDE.md, skills, plugins, settings.json,
#       MCP servers, .claude.json, credentials.
#
#   --user-data-dir   -> ~/.claude/<slug>/app
#       Desktop app surface: auth tokens, chat history, connectors,
#       Cowork VM bundles.
#
# These are independent surfaces. Setting only one leaves the other shared.
#
# Icons are copied verbatim from Claude.app — every bundle uses the stock
# icon set at all resolutions. No recoloring.

set -euo pipefail

CLAUDE_APP="${CLAUDE_APP:-/Applications/Claude.app}"
DEST="${CLAUDE_LAUNCHER_DIR:-${HOME}/Applications}"
PROFILE_ROOT="${HOME}/.claude"
BUNDLE_ID_PREFIX="local.${USER}.claude-launcher"
PERSONAL_NAME="$(printf '%s' "${USER:0:1}" | tr '[:lower:]' '[:upper:]')${USER:1}"

# slug|Bundle display name
PROFILES=(
  "${USER}|Claude (${PERSONAL_NAME})"
  "curewise|Claude (CureWise)"
)

# ----------------------------------------------------------------- checks ---

[ -d "$CLAUDE_APP" ] || { echo "Not found: $CLAUDE_APP" >&2; exit 1; }
mkdir -p "$DEST"

# --------------------------------------------------------- locate the icon ---

ICON_NAME="$(defaults read "$CLAUDE_APP/Contents/Info" CFBundleIconFile 2>/dev/null || true)"
SRC_ICNS="$CLAUDE_APP/Contents/Resources/${ICON_NAME%.icns}.icns"

if [ ! -f "$SRC_ICNS" ]; then
  # Fall back to the largest .icns in Resources.
  SRC_ICNS="$(find "$CLAUDE_APP/Contents/Resources" -maxdepth 1 -name '*.icns' \
    -exec stat -f '%z %N' {} + | sort -rn | head -1 | cut -d' ' -f2-)"
fi
[ -f "$SRC_ICNS" ] || { echo "No .icns found in $CLAUDE_APP" >&2; exit 1; }
echo "Icon source: $SRC_ICNS"
echo

# ----------------------------------------------------------------- build ----

for entry in "${PROFILES[@]}"; do
  IFS='|' read -r slug name <<< "$entry"

  APP="$DEST/$name.app"
  CONFIG_DIR="$PROFILE_ROOT/$slug/claude-code"
  APP_DIR="$PROFILE_ROOT/$slug/app"

  echo "Building $APP"
  echo "  CLAUDE_CONFIG_DIR -> $CONFIG_DIR"
  echo "  --user-data-dir   -> $APP_DIR"

  # Pre-create so neither surface races on first launch. Harmless if present.
  mkdir -p "$CONFIG_DIR" "$APP_DIR"

  rm -rf "$APP"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

  # ${HOME} stays literal so the bundle resolves it at launch time.
  cat > "$APP/Contents/MacOS/launch" <<EOF
#!/bin/sh
exec /usr/bin/open -n \\
  --env "CLAUDE_CONFIG_DIR=\${HOME}/.claude/${slug}/claude-code" \\
  "${CLAUDE_APP}" \\
  --args "--user-data-dir=\${HOME}/.claude/${slug}/app"
EOF
  chmod +x "$APP/Contents/MacOS/launch"

  # LSUIElement: the wrapper execs and exits, so it must not claim a Dock
  # tile of its own. The visible tile belongs to Claude.app.
  cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${name}</string>
  <key>CFBundleDisplayName</key><string>${name}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID_PREFIX}.${slug}</string>
  <key>CFBundleExecutable</key><string>launch</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

  # Stock Claude icon, unmodified.
  cp "$SRC_ICNS" "$APP/Contents/Resources/AppIcon.icns"

  # Ad-hoc signature. Keeps Gatekeeper and TCC prompts stable across rebuilds.
  codesign --force --sign - "$APP" 2>/dev/null \
    || echo "  ! codesign failed (non-fatal)" >&2

  touch "$APP"
  echo
done

# -------------------------------------------------------------- register ----

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
for entry in "${PROFILES[@]}"; do
  IFS='|' read -r slug name <<< "$entry"
  "$LSREGISTER" -f "$DEST/$name.app"
done
killall Dock 2>/dev/null || true

# ---------------------------------------------------------------- verify ----

echo "Built:"
for entry in "${PROFILES[@]}"; do
  IFS='|' read -r slug name <<< "$entry"
  printf '  %-24s %s\n' "$name.app" \
    "$(du -sh "$PROFILE_ROOT/$slug" 2>/dev/null | cut -f1) in ~/.claude/$slug"
done

echo
echo "Sign in to each launcher once with the other quit — the claude://"
echo "callback goes to whichever instance registered the scheme last."
