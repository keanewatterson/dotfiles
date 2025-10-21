Use ${XDG_DATA_HOME}/chezmoi/home/.chezmoidata/instance-options.toml to enable or disable specific settings, perhaps similar to feature flags, without source control versioning.

Key-value pairs defined as instance.options may be evaluated in .zshrc for scenario-specific or ephemeral behavior.

```sh
# settings enabled with ${XDG_DATA_HOME}/chezmoi/home/.chezmoidata/instance-options.toml
{{ if (hasKey .instance "options") -}}

{{ if and (hasKey .instance.options "postgis_docker") (eq .instance.options.postgis_docker true) }}
# -- postgis_docker
alias depg='docker exec -it postgis /bin/bash'
alias dspg='docker start postgis'
alias dxpg='docker stop postgis'
{{- end }}

{{- end }}
```


```sh
cat ${XDG_DATA_HOME}/chezmoi/home/.chezmoidata/instance-options.toml

[instance.options]
postgis_docker=true
```
