#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}

_t0=$(date +%s.%N)

bin_dir="${HOME}/.local/bin"
url="https://micro.mamba.pm/install.sh"
installer="$(mktemp -t mamba-install-XXX.sh)"

if ! [[ -f "${bin_dir}/micromamba" ]]; then
    log_info "Installing Micromamba"

    curl -fsSL "${url}" -o "${installer}";

    mkdir -p "${bin_dir}"

    CONDA_FORGE_YES="yes" \
        INIT_YES="N" \
        MAMBA_ROOT_PREFIX="${XDG_DATA_HOME}/mamba" \
        PREFIX_LOCATION="${XDG_DATA_HOME}/mamba" \
        /bin/zsh "${installer}" <&-
    
    rm "${installer}"

    _t1=$(date +%s.%N)
    _sec=$(printf "%.3f" "$(echo "$_t1 - $_t0" | bc -l)")

    log_info "Micromamba installation completed: seconds: ${_sec}"
else
    log_info "Micromamba is installed"
fi
