#!/bin/zsh

set -efo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}
{{ template "init-sdkman.zsh" . }}

log_info "Installing sdkman Java packages"

{{ $java_distros := .instance.packages.config.sdkman.java_distros -}}

distros=({{ range $i, $e := $java_distros }}"{{ $e }}" {{ end -}})

# something in sdk indicates error and triggers termination
set +e
for distro in "${distros[@]}"; do

    ident="$(sdk list java | grep ${distro} | awk -F'|' '{print $6}' | tr -d ' ')"
    log_info "Install ${distro} ${ident}"
    sdk install java "${ident}"
done
set -e
