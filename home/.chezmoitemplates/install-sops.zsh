#!/usr/bin/env zsh

@ sonnet-4.6

# install_sops.zsh
# Downloads, verifies SHA-256 checksum, and installs the latest sops binary.
# Supports: Ubuntu and Fedora on amd64 and arm64.
# sops releases plain binaries (no .deb/.rpm) — installed directly to /usr/local/bin.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly SOPS_REPO="getsops/sops"
readonly GITHUB_API="https://api.github.com/repos/${SOPS_REPO}/releases/latest"
readonly INSTALL_DIR="/usr/local/bin"
readonly TMP_DIR="$(mktemp -d)"
readonly MODULE="$(basename $0)"

# ---------------------------------------------------------------------------
# Cleanup — always runs on exit via trap
# ---------------------------------------------------------------------------
cleanup() {
  log_info "Cleaning up temporary directory: ${TMP_DIR}"
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Logging helpers — all write to stderr so $() captures stay clean
# ---------------------------------------------------------------------------
log_info()  { print -- $(date +'%Y-%m-%d %H:%M:%S') "[INFO] (${MODULE}) $*" >&2 }
log_warn()  { print -- $(date +'%Y-%m-%d %H:%M:%S') "[WARN] (${MODULE}) $*" >&2 }
log_error() { print -- $(date +'%Y-%m-%d %H:%M:%S') "[ERROR] (${MODULE}) $*" >&2; exit 1 }

# ---------------------------------------------------------------------------
# Detect CPU architecture
# Prints "amd64" or "arm64" to stdout.
# ---------------------------------------------------------------------------
detect_arch() {
  local machine
  machine="$(uname -m)"
  case "${machine}" in
    x86_64)        print -- "amd64" ;;
    aarch64|arm64) print -- "arm64" ;;
    *) log_error "Unsupported architecture: ${machine}. Only amd64 and arm64 are supported." ;;
  esac
}

# ---------------------------------------------------------------------------
# Detect Linux distribution family (for informational/sudo purposes)
# Prints "debian" or "fedora" to stdout.
# ---------------------------------------------------------------------------
detect_distro() {
  if [[ ! -f /etc/os-release ]]; then
    log_error "/etc/os-release not found — cannot detect distribution."
  fi
  local id
  id=$(. /etc/os-release && print -- "${ID_LIKE:-$ID}")
  case "${id}" in
    *debian*|*ubuntu*) print -- "debian" ;;
    *fedora*|*rhel*|*centos*) print -- "fedora" ;;
    *) log_error "Unsupported distribution (ID='${id}'). Only Ubuntu and Fedora variants are supported." ;;
  esac
}

# ---------------------------------------------------------------------------
# Fetch the tag name of the latest sops release from GitHub.
# Prints the version tag (e.g. "v3.12.1") to stdout.
# ---------------------------------------------------------------------------
fetch_latest_version() {
  log_info "Querying GitHub API for the latest sops release..."
  local version
  if command -v curl &>/dev/null; then
    version=$(curl -fsSL "${GITHUB_API}" \
      | grep '"tag_name"' \
      | head -1 \
      | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
  elif command -v wget &>/dev/null; then
    version=$(wget -qO- "${GITHUB_API}" \
      | grep '"tag_name"' \
      | head -1 \
      | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
  else
    log_error "Neither curl nor wget is available. Please install one and retry."
  fi
  [[ -n "${version}" ]] \
    || log_error "Failed to determine the latest sops version from the GitHub API."
  print -- "${version}"
}

# ---------------------------------------------------------------------------
# Build asset names and download URLs.
# Args: $1=version  $2=arch
# Sets globals: BINARY_FILENAME  BINARY_URL  CHECKSUM_FILENAME  CHECKSUM_URL
# ---------------------------------------------------------------------------
build_urls() {
  local version="$1" arch="$2"
  local base="https://github.com/${SOPS_REPO}/releases/download/${version}"

  # sops release asset naming convention: sops-v3.12.1.linux.amd64
  BINARY_FILENAME="sops-${version}.linux.${arch}"
  CHECKSUM_FILENAME="sops-${version}.checksums.txt"

  BINARY_URL="${base}/${BINARY_FILENAME}"
  CHECKSUM_URL="${base}/${CHECKSUM_FILENAME}"
}

# ---------------------------------------------------------------------------
# Download a single URL to a destination path.
# ---------------------------------------------------------------------------
download_file() {
  local url="$1" dest="$2"
  log_info "Downloading: ${url}"
  if command -v curl &>/dev/null; then
    curl -fsSL --output "${dest}" "${url}" \
      || log_error "Download failed: ${url}"
  else
    wget -qO "${dest}" "${url}" \
      || log_error "Download failed: ${url}"
  fi
}

# ---------------------------------------------------------------------------
# Download the sops binary and checksum file into TMP_DIR.
# ---------------------------------------------------------------------------
download_assets() {
  download_file "${BINARY_URL}"   "${TMP_DIR}/${BINARY_FILENAME}"
  download_file "${CHECKSUM_URL}" "${TMP_DIR}/${CHECKSUM_FILENAME}"
}

# ---------------------------------------------------------------------------
# Verify the SHA-256 checksum of the downloaded binary.
# Aborts via log_error() on mismatch.
# ---------------------------------------------------------------------------
verify_checksum() {
  log_info "Verifying SHA-256 checksum for ${BINARY_FILENAME}..."

  local checksum_line expected_hash actual_hash

  checksum_line=$(grep "${BINARY_FILENAME}" "${TMP_DIR}/${CHECKSUM_FILENAME}" || true)
  [[ -n "${checksum_line}" ]] \
    || log_error "No checksum entry found for '${BINARY_FILENAME}' in ${CHECKSUM_FILENAME}."

  expected_hash=$(print -- "${checksum_line}" | awk '{print $1}')

  if command -v sha256sum &>/dev/null; then
    actual_hash=$(sha256sum "${TMP_DIR}/${BINARY_FILENAME}" | awk '{print $1}')
  elif command -v shasum &>/dev/null; then
    actual_hash=$(shasum -a 256 "${TMP_DIR}/${BINARY_FILENAME}" | awk '{print $1}')
  else
    log_error "No SHA-256 tool found (sha256sum / shasum). Cannot verify checksum."
  fi

  if [[ "${expected_hash}" == "${actual_hash}" ]]; then
    log_info "Checksum verified successfully."
    log_info "  Expected : ${expected_hash}"
    log_info "  Actual   : ${actual_hash}"
  else
    log_error "Checksum MISMATCH — aborting installation.\n  Expected : ${expected_hash}\n  Actual   : ${actual_hash}"
  fi
}

# ---------------------------------------------------------------------------
# Install the verified binary to INSTALL_DIR.
# Uses sudo if not already root.
# ---------------------------------------------------------------------------
install_binary() {
  local src="${TMP_DIR}/${BINARY_FILENAME}"
  local dest="${INSTALL_DIR}/sops"
  local sudo_cmd=""

  [[ "${EUID:-$(id -u)}" -ne 0 ]] && sudo_cmd="sudo"

  log_info "Installing sops to ${dest}..."
  ${sudo_cmd} install -m 0755 "${src}" "${dest}" \
    || log_error "Installation to ${dest} failed."
  log_info "sops installed successfully."
}

# ---------------------------------------------------------------------------
# Confirm the installed binary is on PATH and report its version.
# ---------------------------------------------------------------------------
verify_install() {
  if command -v sops &>/dev/null; then
    local installed_version
    installed_version=$(sops --version 2>&1 | head -1)
    log_info "Installed: ${installed_version}"
  else
    log_warn "sops not found in PATH after installation. You may need to open a new shell."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  if ! command -v "sops" >/dev/null 2>&1; then
    log_info "Installing sops"

    local distro arch version
    distro=$(detect_distro)
    arch=$(detect_arch)
    log_info "Detected distro family : ${distro}"
    log_info "Detected architecture  : ${arch}"

    version=$(fetch_latest_version)
    log_info "Latest sops version    : ${version}"

    build_urls "${version}" "${arch}"
    log_info "Binary URL   : ${BINARY_URL}"
    log_info "Checksum URL : ${CHECKSUM_URL}"

    download_assets
    verify_checksum
    install_binary
    verify_install

    log_info "sops installation complete"
    else
        log_info "sops is installed"
    fi
}

main "$@"