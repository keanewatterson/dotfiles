# dotfiles

Dotfiles and package installation for macOS and Ubuntu managed with [chezmoi](https://chezmoi.io).

## Quick Start
Install chezmoi using default installer and initialize via public repository.

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --apply https://github.com/keanewatterson/dotfiles.git
```

## Development
Evaluate template modifications based on chezmoi mode.
```sh
# initialization
chezmoi init --source . --config /tmp/test-chezmoi-init.toml

# general case
chezmoi execute-template < test.tmpl > /tmp/test.txt
chezmoi apply --dry-run
```
