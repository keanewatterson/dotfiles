#!/bin/zsh

# remove chezmoi and mostly reset

typeset -a path_list=(
    ${XDG_CACHE_HOME}/nvim
    ${XDG_CONFIG_HOME}/chezmoi
    ${XDG_CONFIG_HOME}/oh-my-posh
    ${XDG_CONFIG_HOME}/zsh
    ${XDG_DATA_HOME}/chezmoi
    ${XDG_DATA_HOME}/nvim
    ${XDG_STATE_HOME}/nvim
    ${HOME}/.local//bin/chezmoi
    ${HOME}/.config/zsh
    ${HOME}/.config/nvim
    ${HOME}/.zshenv
    ${HOME}/.gitconfig
    ${HOME}/.gitignore_global
    ${HOME}/.conda
    ${HOME}/.mamba
    ${HOME}/.ssh
)


for elem in ${path_list}; do

    if [[ -f "${elem}" ]]; then
        rm "${elem}" || printf "Unable to delete file: ${elem}\n"
        printf "Deleted path: ${elem}\n"
    elif [[ -d "${elem}" ]]; then
        rm -rf "${elem}" || printf "Unable to delete directory: ${elem}\n"
    else
        printf "Unable find path: ${elem}\n"
    fi
done
