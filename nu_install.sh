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
  rm -rf "${folder}"
}

add_shell_config() {
  local shell_config

  if [ -w "$HOME/.bashrc" ]; then
    shell_config="$HOME/.bashrc"
  elif [ -w "$HOME/.profile" ]; then
    shell_config="$HOME/.profile"
  else
    echo "No writable shell config found. Please add 'nu' manually."
    return 1
  fi

  # Only add alias if it's not already there
  if ! grep -x "nu" "$shell_config"; then
    echo "nu" >>"$shell_config"
    echo "Added nushell in $shell_config"
  else
    echo "nushell already set in $shell_config"
  fi
}

remove_shell_config() {
  local shell_config

  if [ -w "$HOME/.bashrc" ]; then
    shell_config="$HOME/.bashrc"
  elif [ -w "$HOME/.profile" ]; then
    shell_config="$HOME/.profile"
  else
    echo "No writable shell config found."
    return 1
  fi

  sed -i '/^nu/d' "$shell_config"
  echo "Removed nu from $shell_config"
}

print_msg() {
  echo "To remove nu, run the following commands:"
  echo "  rm /usr/local/bin/nu"
  echo "  rm -rf ~/.config/nushell"
}

# Main Script

main() {
  if [ -f /usr/local/bin/nu ]; then
    echo "nu is already installed in /usr/local/bin."
    read -p "Do you want to remove the existing nushell installation? [y/N]: " response
    case "$response" in [yY])
      echo "Removing existing nushell..."
      sudo rm /usr/local/bin/nu
      rm -rf "$HOME/.config/nushell"
      remove_shell_config
      ;;
    esac
    exit 0
  fi

  echo "Fetching the latest nushell version..."
  VERSION=$(get_latest_version)

  echo "Latest version: ${VERSION}"

  echo "Mapping architecture..."
  ARCH=$(map_architecture)

  echo "Architecture: ${ARCH}"

  download_binary "${VERSION}" "${ARCH}"
  install_nushell "${VERSION}" "${ARCH}"

  echo "nushell ${VERSION} installed successfully."
  add_shell_config
  print_msg
}

main
