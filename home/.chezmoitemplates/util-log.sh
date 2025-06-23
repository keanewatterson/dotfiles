# >>> util-log.sh
_log_debug="${_log_debug:-false}"
#_log_module="${0:t}"
_log_module=$(basename $0)

log_debug() {
    if "${_log_debug}"; then log_message "DEBUG" "$1"; fi
}

log_error() {
    log_message "ERROR" "$1"
}

log_info() {
    log_message "INFO" "$1"
}

log_warn() {
    log_message "WARN" "$1"
}

log_message() {
    # printf "$(date +'%Y-%m-%d %H:%M:%S') [${(U)1}] ($_log_module) ${2}\n"
    printf "$(date +'%Y-%m-%d %H:%M:%S') [${1}] ($_log_module) ${2}\n"
}

# alias log_error="log_message 'ERROR'"
# alias log_info="log_message 'INFO'"
# alias log_warn="log_message 'WARN'"
# <<< util-log.sh
