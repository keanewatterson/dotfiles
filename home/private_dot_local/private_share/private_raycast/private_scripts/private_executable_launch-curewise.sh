#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Launch CureWise
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 💼
# @raycast.packageName Workspace

apps=(
  "/System/Applications/Mail.app"
  "/System/Applications/Calendar.app"
  "/System/Applications/Messages.app"
  "/System/Applications/Passwords.app"
  "/Applications/Google Chrome.app"
  "/Applications/Slack.app"
  "/Applications/Linear.app"
  "/Applications/Todoist.app"
  "${HOME}/Applications/Claude (CureWise).app"
)

for app in "${apps[@]}"; do
  [[ -d "$app" ]] && open -gj "$app"
done

