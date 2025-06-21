# >>> util-log.zsh
alias log_error="log_message 'ERROR'"
alias log_info="log_message 'INFO'"
alias log_warn="log_message 'WARN'"

_log_debug="${_log_debug:-false}"
_log_module="${0:t}"

log_debug() {
    if "${_log_debug}"; then log_message "DEBUG" "$1"; fi
}

log_message() {
    printf "$(date +'%Y-%m-%d %H:%M:%S') [${(U)1}] ($_log_module) ${2}\n"
}
# <<< util-log.zsh
