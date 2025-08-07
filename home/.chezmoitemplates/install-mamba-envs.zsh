#!/bin/zsh

set -euo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}
{{ template "init-mamba.zsh" . }}

printf "Installing mamba environments\n"

{{ $config_envs := .instance.packages.config.mamba.environments -}}

env_names=({{ range $i, $e := $config_envs }}"{{ $e }}" {{ end -}})

template_dir={{ .instance.packages.config.template_dir }}

for env_name in "${env_names[@]}"; do

    if ! [[ -d ${MAMBA_ROOT_PREFIX}/envs/${env_name} ]]; then
        env_file="${template_dir}/mamba-${env_name}.yaml"

        log_info "Creating environment: ${env_name}\n"
        micromamba env create -y -f "${env_file}"
    else
        log_info "Environment installed: ${env_name}"
    fi
done
