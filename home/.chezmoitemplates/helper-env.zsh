# environment
XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME}/zsh}"

path=($path ${HOME}/.local/bin)

_log_debug="${_log_debug:-false}"
_log_module="${0:t}"

umask 077
