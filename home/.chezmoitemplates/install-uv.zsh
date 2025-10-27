#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}


if ! [[ -f "${HOME}/.local/bin/uv" ]]; then
    log_info "Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
else
    log_info "uv is installed\n"
fi
