# dotfiles

Dotfiles and package installation for macOS and Ubuntu managed with [chezmoi](https://chezmoi.io).


Install chezmoi using default installer and initialize via public repository.

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --dry-run --apply https://github.com/keanewatterson/dotfiles.git

sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --apply https://github.com/keanewatterson/dotfiles.git
```
