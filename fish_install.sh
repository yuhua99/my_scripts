#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

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
    echo -e "${RED}Unsupported architecture: $arch${NC}" >&2
    exit 1
    ;;
  esac
}

download_binary() {
  local version="$1"
  local arch="$2"
  local file="fish-static-${arch}-${version}.tar.xz"
  local url="${DOWNLOAD_URL_BASE}/${version}/${file}"

  echo -e "${YELLOW}Downloading ${file}...${NC}"
  curl -L -o "${file}" "${url}"
}

install_shell() {
  local version="$1"
  local arch="$2"
  local folder="fish-static-${arch}-${version}"
  local file="${folder}.tar.xz"

  echo -e "${YELLOW}Extracting ${file}...${NC}"
  mkdir -p "${folder}"
  tar -xJf "${file}" -C "${folder}"

  echo -e "${YELLOW}Installing fish shell...${NC}"
  sudo mv ${folder}/fish /usr/local/bin/

  echo -e "${YELLOW}Cleaning up...${NC}"
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
    echo -e "${GREEN}Created new shell config file at $HOME/.profile${NC}"
  else
    echo -e "${RED}No writable shell config found. Please add 'fish' manually.${NC}"
    return 1
  fi

  # check if nu exists
  if ! grep -x "fish" "$shell_config"; then
    echo "fish" >>"$shell_config"
    echo -e "${GREEN}Added fish-shell in $shell_config${NC}"
  else
    echo -e "${YELLOW}fish-shell already set in $shell_config${NC}"
  fi
}

remove_shell_config() {
  local shell_config

  if [ -w "$HOME/.bashrc" ]; then
    shell_config="$HOME/.bashrc"
  elif [ -w "$HOME/.profile" ]; then
    shell_config="$HOME/.profile"
  else
    echo -e "${RED}No writable shell config found.${NC}"
    return 1
  fi

  sed -i '/^fish/d' "$shell_config"
  echo -e "${GREEN}Removed fish from $shell_config${NC}"
}

print_msg() {
  echo -e "${YELLOW}To remove fish, run the following commands:${NC}"
  echo -e "${YELLOW}  rm /usr/local/bin/fish${NC}"
  echo -e "${YELLOW}  rm -rf ~/.config/fish${NC}"
}

# Main Script

main() {
  if [ -f /usr/local/bin/fish ]; then
    echo -e "${YELLOW}fish is already installed in /usr/local/bin.${NC}"
    read -r -p "Do you want to remove the existing fish-shell installation? [y/N]: " response </dev/tty
    case "$response" in [yY])
      echo -e "${YELLOW}Removing existing fish-shell...${NC}"
      sudo rm /usr/local/bin/fish
      rm -rf "$HOME/.config/fish"
      remove_shell_config
      ;;
    esac
    exit 0
  fi

  echo -e "${YELLOW}Fetching the latest fish-shell version...${NC}"
  VERSION=$(get_latest_version)

  echo -e "${GREEN}Latest version: ${VERSION}${NC}"

  echo -e "${YELLOW}Mapping architecture...${NC}"
  ARCH=$(map_architecture)

  echo -e "${GREEN}Architecture: ${ARCH}${NC}"

  download_binary "${VERSION}" "${ARCH}"
  install_shell "${VERSION}" "${ARCH}"

  echo -e "${GREEN}fish-shell ${VERSION} installed successfully.${NC}"
  add_shell_config
  print_msg
}

main
