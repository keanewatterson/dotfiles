# >>> init-env.sh
XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME}/zsh}"

PATH=$PATH:${HOME}/.local/bin
{{ if eq .chezmoi.os "darwin" -}}
PATH=$PATH:/opt/homebrew/bin
{{ end -}}

umask 077
# <<< init-env.sh
