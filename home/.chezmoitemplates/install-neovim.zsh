{{ if or (eq .instance.os_distro "debian-rpi") (eq .instance.os_distro "ubuntu-tegra") -}}
#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}

{{ $path_list := (list
  "/bin"
  "/usr/bin"
  "/usr/local/bin"
  (joinPath .chezmoi.homeDir ".local" "bin")
  )
-}}


{{ if not (findExecutable "nvim" $path_list) -}}
    log_info "Installing Neovim AppImage"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.appimage" \
        -o "${HOME}/.local/bin/nvim.appimage"
    chmod 700 "${HOME}/.local/bin/nvim.appimage"
    ln -s "${HOME}/.local/bin/nvim.appimage" "${HOME}/.local/bin/nvim"
{{ else -}}
    log_info "Neovim is installed\n"
{{ end -}}

{{ end -}}
