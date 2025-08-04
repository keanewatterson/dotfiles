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

{{ $section := "" -}}
{{ $crates := "" -}}

# -- darwin
{{ if eq .instance.os_distro "darwin" -}}
{{   $section = index .packages.darwin $scope -}}
# -- ubuntu
{{ else if eq .instance.os_distro "linux-ubuntu" -}}
{{   $section = index .packages.linux.ubuntu $scope -}}
# -- fedora
{{ else if eq .instance.os_distro "linux-fedora" -}}
{{   $section = index .packages.linux.fedora $scope -}}
# -- debian (raspbian)
{{ else if eq .instance.os_distro "linux-debian" -}}
{{   $section = index .packages.linux.debian $scope -}}
{{ end }}


{{ $crates := $section.cargo | sortAlpha | uniq -}}
{{   range $crates -}}
    cargo install {{ . }}
{{   end }}

_t1=$(date +%s.%N)
_sec=$(printf "%.3f" "$(echo "$_t1 - $_t0" | bc -l)")

log_info "Cargo installations completed: seconds: ${_sec}"

{{ else -}}
log_info "Cargo is not enabled"

{{ end -}}
