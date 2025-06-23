#!/bin/bash

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}

if [[ ! -f "${XDG_CONFIG_HOME}/chezmoi/key-dotfiles.txt" ]]; then

    mkdir -p "${XDG_CONFIG_HOME}/chezmoi"

    log_info "Decrypting dotfile key"
    chezmoi age decrypt \
        --output "${XDG_CONFIG_HOME}/chezmoi/key-dotfiles.txt" \
        --passphrase "${XDG_DATA_HOME}/chezmoi/resources/keys/key-dotfiles.txt.age"

    chmod 600 "${XDG_CONFIG_HOME}/chezmoi/key-dotfiles.txt"
fi
