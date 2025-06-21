# -- shared functions ---------------------------------------------------------
alias log_error="log_message 'ERROR'"
alias log_info="log_message 'INFO'"
alias log_warn="log_message 'WARN'"

log_debug() {
    if "${_log_debug}"; then log_message "DEBUG" "$1"; fi
}

log_message() {
    printf "$(date +'%Y-%m-%d %H:%M:%S') [${(U)1}] ($_log_module) ${2}\n"
}
