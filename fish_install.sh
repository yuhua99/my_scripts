#!/bin/bash

set -e

# Constants
REPO_URL="https://github.com/fish-shell/fish-shell"
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
    echo "amd64"
    ;;
  aarch64 | arm64)
    echo "aarch64"
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
  local file="fish-static-${arch}-${version}.tar.xz"
  local url="${DOWNLOAD_URL_BASE}/${version}/${file}"

  echo "Downloading ${file}..."
  curl -L -o "${file}" "${url}"
}

install_shell() {
  local version="$1"
  local arch="$2"
  local folder="fish-static-${arch}-${version}"
  local file="${folder}.tar.xz"

  echo "Extracting ${file}..."
  mkdir -p "${folder}"
  tar -xJf "${file} -C ${folder}/"

  echo "Installing fish shell..."
  sudo mv ${folder}/fish /usr/local/bin/

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
  elif ! [ -e "$HOME/.profile" ]; then
    touch "$HOME/.profile" && shell_config="$HOME/.profile"
    echo "Created new shell config file at $HOME/.profile"
  else
    echo "No writable shell config found. Please add 'fish' manually."
    return 1
  fi

  # check if nu exists
  if ! grep -x "fish" "$shell_config"; then
    echo "fish" >>"$shell_config"
    echo "Added fish-shell in $shell_config"
  else
    echo "fish-shell already set in $shell_config"
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

  sed -i '/^fish/d' "$shell_config"
  echo "Removed fish from $shell_config"
}

print_msg() {
  echo "To remove fish, run the following commands:"
  echo "  rm /usr/local/bin/fish"
  echo "  rm -rf ~/.config/fish"
}

# Main Script

main() {
  if [ -f /usr/local/bin/fish ]; then
    echo "fish is already installed in /usr/local/bin."
    read -r -p "Do you want to remove the existing fish-shell installation? [y/N]: " response </dev/tty
    case "$response" in [yY])
      echo "Removing existing fish-shell..."
      sudo rm /usr/local/bin/fish
      rm -rf "$HOME/.config/fish"
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
  install_shell "${VERSION}" "${ARCH}"

  echo "fish-shell ${VERSION} installed successfully."
  add_shell_config
  print_msg
}

main
