# dotfiles

Dotfiles and package installation for macOS and Ubuntu managed with [chezmoi](https://chezmoi.io).


Install chezmoi using default installer and initialize via public repository.

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --apply https://github.com/keanewatterson/dotfiles.git
```

### Ephemeral Host Settings

Use ${XDG_CONFIG_HOME}/chezmoi/home/.chezmoidata/instance-options.toml to enable ephemeral or specific settings that are defined in .zshrc but may not be relevant for all hosts. The instance-options.toml file is not managed by chezmoi nor versioned.

Example:
```sh
[instance.options]
postgis_docker=true
```


### New Platform Testing

```
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --dry-run --apply https://github.com/keanewatterson/dotfiles.git
```
