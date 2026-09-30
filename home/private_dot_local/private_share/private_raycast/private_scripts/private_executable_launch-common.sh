##!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Launch Common
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🏠
# @raycast.packageName Workspace

apps=(
  "/System/Applications/Mail.app"
  "/System/Applications/Calendar.app"
  "/System/Applications/Messages.app"
  "/System/Applications/Passwords.app"
  "${HOME}/Applications/Claude (Keane).app"
)

for app in "${apps[@]}"; do
  [[ -d "$app" ]] && open -gj "$app"
done

