# dotfiles

Dotfiles for macOS and linux which are managed with [chezmoi](https://chezmoi.io).


Install chezmoi and apply dotfiles:

```sh

sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --dry-run --apply git@github.com:keanewatterson/dotfiles.git --ssh

sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --apply git@github.com:keanewatterson/dotfiles.git --ssh

sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --apply https://github.com/keanewatterson/dotfiles.git
```
