#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}


if ! [[ -d "${HOME}/.juliaup" ]]; then
    log_info "Installing Julia"
    curl -fsSL https://install.julialang.org | sh -s -- --yes --add-to-path=no
else
    log_info "Julia is installed\n"
fi
