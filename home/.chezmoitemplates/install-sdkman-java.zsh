#!/bin/zsh

# enable sdkman java installations in packages-name.toml, for example
# in packages-darwwin.toml:
#   [data.instance.packages.config.sdkman]
#   java_distros = [
#    "Corretto"
#   ]

# initialize for example:
#   init-sdkman

set -efo pipefail

{{ template "init-env.sh" . }}
{{ template "util-log.sh" . }}
{{ template "init-sdkman.zsh" . }}

log_info "Installing sdkman Java packages"

{{ $packages := include (printf ".chezmoitemplates/packages-%s.toml" .instance.os_distro) | fromToml -}}
{{ $data := get $packages "data" | default (dict) -}}
{{ $instance := get $data "instance" | default (dict) -}}
{{ $packages_root := get $instance "packages" | default (dict) -}}
{{ $config_root := get $packages_root "config" | default (dict) -}}
{{ $config := get $config_root "sdkman" | default (dict) -}}
{{ $java_distros := get $config "java_distros" | default (list) -}}

distros=({{ range $i, $e := $java_distros }}"{{ $e }}" {{ end -}})

# something in sdk indicates error and triggers termination
set +e
for distro in "${distros[@]}"; do

    ident="$(sdk list java | grep ${distro} | awk -F'|' '{print $6}' | tr -d ' ')"
    log_info "Install ${distro} ${ident}"
    sdk install java "${ident}"
done
set -e
