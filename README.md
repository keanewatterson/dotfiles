# dotfiles

Dotfiles and package installation for macOS and linux managed with [chezmoi](https://chezmoi.io).

## Quick Start
Install chezmoi using default installer and initialize via public repository.

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin" init --apply https://github.com/keanewatterson/dotfiles.git
```

Optionally set ephemeral or non-generalized settings via the `instance-options.toml` file in .chezmoi.sourceDir/.chezmoidata. Configuration here is added to .zshrc. The file is referenced only during `chezmoi init`, is not chezmoi-managed, and is not version controlled.

```toml
[instance.options]
include-zshrc = ["serial-console"]

docker-dev = [
  "# -- docker-dev ..."
]
serial-console = [
  "# -- serial-console",
  "alias s96='screen /dev/ttyUSB0 9600'",
  "alias s115='screen /dev/ttyUSB0 115200'"
]
```


## Portable paths and profiles

User paths resolve from `${HOME}`, `${USER}`, and XDG variables. Chezmoi helpers
use the configured working tree and source directory, including custom checkout
locations. Existing instance options are preserved during finalization.

Set optional shell exports in the local instance options or iin the calling environment.


## Development
Evaluate template modifications based on chezmoi mode.
```sh
# initialization
chezmoi init --source . --config /tmp/test-chezmoi-init.toml

# general case
chezmoi execute-template < /tmp/test.tmpl
chezmoi edit /path/to/encrypted-template

chezmoi -v apply --dry-run
```


