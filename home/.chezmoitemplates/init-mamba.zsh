# >>> init-mamba.zsh
{{ if lookPath "micromamba" -}}

export MAMBA_EXE="{{- lookPath "micromamba" -}}"
export MAMBA_ROOT_PREFIX="${XDG_DATA_HOME}/mamba"

__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"
fi
unset __mamba_setup
{{ else -}}
printf "Unable to initialize mamba: micromamba not found\n"
return 1
{{ end -}}
# <<< init-mamba.zsh
