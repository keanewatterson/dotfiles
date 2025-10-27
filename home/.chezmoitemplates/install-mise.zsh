#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}


if ! [[ -f "${HOME}/.local/bin/mise" ]]; then
    log_info "Installing mise"
    curl -LsSf https://mise.run | sh
else
    log_info "mise is installed\n"
fi