#!/bin/bash

set -e

# Constants
REPO_URL="https://github.com/nushell/nushell"
DOWNLOAD_URL_BASE="${REPO_URL}/releases/download"

# Functions

get_latest_version() {
  curl -s -L -o /dev/null -w '%{url_effective}' "${REPO_URL}/releases/latest" |
    awk -F'/tag/' '{print $2}'
}

map_architecture() {
  local arch
  arch=$(uname -m)
  case "$arch" in
  x86_64)
    echo "x86_64-unknown-linux-gnu"
    ;;
  aarch64 | arm64)
    echo "aarch64-unknown-linux-gnu"
    ;;
  armv7*)
    echo "armv7-unknown-linux-gnueabihf"
    ;;
  loongarch64)
    echo "loongarch64-unknown-linux-gnu"
    ;;
  riscv64)
    echo "riscv64gc-unknown-linux-gnu"
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 1
    ;;
  esac
}

download_binary() {
  local version="$1"
  local arch="$2"
  local file="nu-${version}-${arch}.tar.gz"
  local url="${DOWNLOAD_URL_BASE}/${version}/${file}"

  echo "Downloading ${file}..."
  curl -L -o "${file}" "${url}"
}

install_nushell() {
  local version="$1"
  local arch="$2"
  local folder="nu-${version}-${arch}"
  local file="${folder}.tar.gz"

  echo "Extracting ${file}..."
  tar -xzf "${file}"

  echo "Installing nushell..."
  sudo mv ${folder}/nu /usr/local/bin/

  echo "Cleaning up..."
  rm "${file}"
  rm -rf "nu-${version}-${arch}"
}

# Main Script

main() {
  echo "Fetching the latest nushell version..."
  VERSION=$(get_latest_version)

  echo "Latest version: ${VERSION}"

  echo "Mapping architecture..."
  ARCH=$(map_architecture)

  echo "Architecture: ${ARCH}"

  download_binary "${VERSION}" "${ARCH}"
  install_nushell "${VERSION}" "${ARCH}"

  echo "nushell ${VERSION} installed successfully."
  echo "To remove nu, simply rm it from /usr/local/bin/"
}

main
