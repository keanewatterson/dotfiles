# >>> init-mamba.zsh
export MAMBA_EXE="$(which micromamba)"
export MAMBA_ROOT_PREFIX="${XDG_DATA_HOME}/mamba"

__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"
fi
unset __mamba_setup
# <<< init-mamba.zsh
