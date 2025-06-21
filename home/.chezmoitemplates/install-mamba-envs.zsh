#!/bin/zsh

set -eufo pipefail

{{ template "helper-env.zsh" . }}
{{ template "helper-functions.zsh" . -}}
{{ template "mamba-init.zsh" . -}}

printf "Installing mamba environments\n"

{{ $config_envs := .packages.config.mamba.environments }}
env_names=({{ range $i, $e := $config_envs }}"{{ $e }}" {{ end }})

template_dir={{ .packages.config.template_dir }}

for env_name in "${env_names[@]}"; do
    if ! [[ -d ${MAMBA_ROOT_PREFIX}/envs/${env_name} ]]; then
        env_file="${template_dir}/mamba-${env_name}.yaml"

        log_info "Creating environment: ${env_name}\n"
        micromamba env create -y -f "${env_file}"
    else
        log_info "Environment currently installed: ${env_name}"
    fi
done
