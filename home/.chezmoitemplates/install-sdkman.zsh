#!/bin/zsh

set -eufo pipefail

{{ template "init-env.zsh" . }}
{{ template "util-log.zsh" . -}}

export SDKMAN_DIR="${XDG_DATA_HOME}/sdkman"

if ! [[ -d "${SDKMAN_DIR}" ]]; then
    log_info "Installing SDKMAN!"
    curl -s "https://get.sdkman.io?ci=true&rcupdate=false" | bash
else
    log_info "SDKMAN! is installed\n"
fi
