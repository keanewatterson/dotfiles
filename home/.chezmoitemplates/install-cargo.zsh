#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}

{{ if stat (joinPath .chezmoi.homeDir ".cargo" "bin") -}}

_t0=$(date +%s.%N)

log_info "Installing cargo"

{{ $scope := "desktop" -}}
{{ if .instance.is_machine_headless -}}
{{   $scope = "server" -}}
{{ end -}}

{{ $section := index .instance.packages .instance.os_distro $scope -}}

{{ $crates := $section.cargo | sortAlpha | uniq -}}
{{ range $crates -}}
    log_info "Installing crate: {{ . }}"
    ${HOME}/.cargo/bin/cargo install {{ . }}
{{ end -}}

_t1=$(date +%s.%N)
_sec=$(printf "%.3f" "$(echo "$_t1 - $_t0" | bc -l)")

log_info "Cargo installations completed: seconds: ${_sec}"

{{ else -}}
log_info "Cargo is not enabled"

{{ end -}}
