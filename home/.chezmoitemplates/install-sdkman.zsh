#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}


if ! [[ -d "${XDG_DATA_HOME}/sdkman" ]]; then
    export SDKMAN_DIR="${XDG_DATA_HOME}/sdkman"
    log_info "Installing SDKMAN!"
    curl -s "https://get.sdkman.io?ci=true&rcupdate=false" | bash
else
    log_info "SDKMAN! is installed\n"
fi
