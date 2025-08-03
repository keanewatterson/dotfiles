#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}


if ! [[ -d "${HOME}/.cargo" ]]; then
    log_info "Installing rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y
else
    log_info "rust is installed\n"
fi
