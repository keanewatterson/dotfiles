#!/bin/sh

# -e: exit on error
# -u: exit on unset variables
set -eu



if ! chezmoi="$(command -v chezmoi)"; then

	if [ "$(uname)" = "Darwin" ]; then

		bin_dir="/opt/homebrew/bin"
		if ! [ -f "${bin_dir}/brew" ]; then
			echo "Installing homebrew - root permission required" >&2
			CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi

		eval "$(${bin_dir}/brew shellenv)"

		chezmoi="${bin_dir}/chezmoi"
		echo "Installing chezmoi to '${chezmoi}'" >&2
		"${bin_dir}/brew" install chezmoi
		unset bin_dir
	else
		bin_dir="${HOME}/.local/bin"
		chezmoi="${bin_dir}/chezmoi"
		echo "Installing chezmoi to '${chezmoi}'" >&2
		if command -v curl >/dev/null; then
			chezmoi_install_script="$(curl -fsSL get.chezmoi.io)"
		elif command -v wget >/dev/null; then
			chezmoi_install_script="$(wget -qO- get.chezmoi.io)"
		else
			echo "To install chezmoi, you must have curl or wget installed." >&2
			exit 1
		fi
		sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
		unset chezmoi_install_script bin_dir
	fi

fi

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

set -- init --apply --source="${script_dir}"

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
