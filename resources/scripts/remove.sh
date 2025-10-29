#!/bin/bash

# remove chezmoi and mostly reset

XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

typeset -a path_list=(

    ${HOME}/.gitconfig
    ${HOME}/.gitignore_global
    ${HOME}/.ssh

    ${XDG_CACHE_HOME}/mise
    ${XDG_CONFIG_HOME}/mise
    ${XDG_DATA_HOME}/mise
    ${XDG_STATE_HOME}/mise


    ${XDG_CACHE_HOME}/nvim
    ${XDG_CONFIG_HOME}/nvim
    ${XDG_DATA_HOME}/nvim
    ${XDG_STATE_HOME}/nvim

    ${XDG_CACHE_HOME}/oh-my-posh
    ${XDG_CONFIG_HOME}/oh-my-posh
    ${XDG_STATE_HOME}/oh-my-posh

    ${XDG_CONFIG_HOME}/chezmoi
    ${XDG_DATA_HOME}/chezmoi
    ${HOME}/.local//bin/chezmoi

    ${XDG_DATA_HOME}/mamba
    ${HOME}/.conda
    ${HOME}/.mamba

    ${XDG_CACHE_HOME}/uv
    ${XDG_DATA_HOME}/mise
    
    ${XDG_DATA_HOME}/zoxide

    ${XDG_CONFIG_HOME}/zsh
    ${HOME}/.zshenv

)


for elem in "${path_list[@]}" do

    if [[ -f "${elem}" ]]; then
        rm "${elem}" || printf "Unable to delete file: ${elem}\n"
        printf "Deleted path: ${elem}\n"
    elif [[ -d "${elem}" ]]; then
        rm -rf "${elem}" || printf "Unable to delete directory: ${elem}\n"
    else
        printf "Unable find path: ${elem}\n"
    fi
done
