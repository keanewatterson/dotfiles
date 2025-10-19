#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}


if ! [[ -d "${XDG_CONFIG_HOME}/nvim" ]]; then
    log_info "Installing NvChad"
    git clone https://github.com/NvChad/starter "${XDG_CONFIG_HOME}/nvim"
    log_info "Install plugins with :MasonInstallAll\n"
else
    log_info "NvChad is installed\n"
fi
