#!/bin/zsh

# enable mamba environment installations in packages-os.toml, for example
# in packages-darwwin.toml:
#   [data.instance.packages.config.mamba]
#   environments = [
#     "clx", "hexc"
#   ]
#   template_dir = "${XDG_DATA_HOME}/chezmoi/resources/templates/mamba"

# initialize an enviroment, for example:
#   source ${ZDOTDIR}/zshfn/init_mamba && init_mamba clx 

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}
{{ template "init-mamba.zsh" . }}

_t0=$(date +%s.%N)

log_info "Installing mamba environments"

{{ $config_envs := .instance.packages.config.mamba.environments -}}

env_names=({{ range $i, $e := $config_envs }}"{{ $e }}" {{ end -}})

template_dir={{ .instance.packages.config.mamba.template_dir }}

for env_name in "${env_names[@]}"; do

    if ! [[ -d ${MAMBA_ROOT_PREFIX}/envs/${env_name} ]]; then
        env_file="${template_dir}/mamba-${env_name}.yaml"

        log_info "Creating environment: ${env_name}\n"
        micromamba env create -y -f "${env_file}"
    else
        log_info "Environment installed: ${env_name}"
    fi
done

_t1=$(date +%s.%N)
_sec=$(printf "%.3f" "$(echo "$_t1 - $_t0" | bc -l)")

log_info "mamba environments completed: seconds: ${_sec}"
