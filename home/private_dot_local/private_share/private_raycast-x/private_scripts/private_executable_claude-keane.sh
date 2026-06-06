#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Start Claude-Keane
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.description Claude with personal data-directory

# Documentation:
# @raycast.author keane_watterson
# @raycast.authorURL https://raycast.com/keane_watterson

open -n -a "/Applications/Claude.app" --args --user-data-dir="${HOME}/Library/Application Support/Claude-Keane"
