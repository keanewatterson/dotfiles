#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}

log_info "Start finalization"

# git repos
log_info "Configure chezmoi repository for ssh protocol"
git -C "${XDG_DATA_HOME}/chezmoi" remote set-url origin git@github.com:{{ .instance.user_github_account }}/dotfiles.git

# instance options
if ! [[ -f "{{ .chezmoi.sourceDir }}/.chezmoidata/instance-options.toml " ]]; then
    mkdir -p "{{ .chezmoi.sourceDir }}/.chezmoidata"
    cp "{{ .chezmoi.workingTree }}/resources/chezmoi/instance-options.toml" \
        "{{ .chezmoi.sourceDir }}/.chezmoidata/instance-options.toml"
fi

# file clean-up
paths_rm=("${HOME}/.zsh_history")

if (( ${#paths_rm} > 0 )); then
    log_info "Remove obsolete files: $paths_rm[@]"
fi

for path_rm in "${paths_rm[@]}"; do
    if [[ -f "${path_rm}" ]]; then
        rm -f "${path_rm}"
    elif [[ -d "${path_rm}" ]]; then
        rm -rf "${path_rm}"
    fi
done

mkdir -p "${HOME}/Projects"


{{/* macos */}}
{{- if eq .chezmoi.os "darwin" -}}

path_tmp="${HOME}/.local/bin/chezmoi"
if [[ -f "/opt/homebrew/bin/chezmoi" && -f "${path_tmp}" ]]; then
    log_info "Remove bootstrap executable: ${path_tmp}"
    rm -f "${path_tmp}"
fi

{{- if (and (.instance.is_machine_virtual) (.instance.enable_system_update)) }}

cname="virtual-$(date +"%Y%m%d")"
log_info "Set ComputerName: ${cname}"
sudo scutil --set ComputerName "${cname}"
{{- end }}

{{- end }}

log_info "Finalization is complete"
