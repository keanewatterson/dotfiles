{{ if or (eq .instance.os_distro "ubuntu") (eq .instance.os_distro "debian-rpi") -}}
#!/bin/zsh

set -euo pipefail

{{- $pathVars := dict -}}
{{- template "path-list.tmpl" (dict "Root" . "Vars" $pathVars) -}}
{{- $pathList := index $pathVars "pathList" }}

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}


{{ if not (findExecutable "nvim" $pathList) -}}
     log_info "Installing Neovim AppImage"
     curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.appimage" \
       -o "${HOME}/.local/bin/nvim.appimage"
     chmod 700 "${HOME}/.local/bin/nvim.appimage"
     ln -s "${HOME}/.local/bin/nvim.appimage" "${HOME}/.local/bin/nvim"
{{ end -}}

{{ end -}}
