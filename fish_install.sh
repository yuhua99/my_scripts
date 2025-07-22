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
  local current_user
  current_user=$(whoami)

  # Add fish to available shells
  echo -e "${YELLOW}Adding fish to available shells...${NC}"
  echo '/usr/local/bin/fish' | sudo tee -a /etc/shells

  # Change user's default shell in /etc/passwd
  echo -e "${YELLOW}Changing default shell to fish for $current_user...${NC}"
  sudo sed -i "s|^$current_user:.*:/bin/.*|$current_user:x:$(id -u):$(id -g):$current_user:/home/$current_user:/usr/local/bin/fish|" /etc/passwd

  # Create fish config directory and add missing paths
  echo -e "${YELLOW}Setting up fish configuration...${NC}"
  mkdir -p "$HOME/.config/fish"

  # Add missing paths permanently to fish config
  cat >>"$HOME/.config/fish/config.fish" <<'EOF'
# Add missing PATH directories
fish_add_path --global /sbin /usr/syno/sbin /usr/syno/bin /usr/local/sbin /usr/local/bin
EOF

  echo -e "${GREEN}Added missing paths to fish configuration${NC}"
}

revert_fish_changes() {
  # Remove fish from /etc/shells
  echo -e "${YELLOW}Removing fish from /etc/shells...${NC}"
  sudo sed -i '\|^/usr/local/bin/fish$|d' /etc/shells
  echo -e "${GREEN}Fish removed from /etc/shells${NC}"
}

restore_user_shell() {
  local current_user
  current_user=$(whoami)

  # Get current shell from /etc/shells (prefer bash, then sh)
  local default_shell="/bin/bash"
  if ! grep -q "^/bin/bash$" /etc/shells; then
    default_shell="/bin/sh"
  fi

  echo -e "${YELLOW}Restoring default shell to $default_shell for $current_user...${NC}"
  # Restore user's shell to default in /etc/passwd
  sudo sed -i "s|^$current_user:.*:/usr/local/bin/fish$|$current_user:x:$(id -u):$(id -g):$current_user:/home/$current_user:$default_shell|" /etc/passwd
  echo -e "${GREEN}Default shell restored to $default_shell${NC}"
}

print_msg() {
  echo -e "${YELLOW}To remove fish, run the following commands:${NC}"
  echo -e "${YELLOW}  rm /usr/local/bin/fish${NC}"
  echo -e "${YELLOW}  rm -rf ~/.config/fish${NC}"
}

# Main Script

main() {
  # Check if $HOME exists
  if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
    echo -e "${RED}Error: \$HOME directory does not exist or is not set.${NC}"
    echo -e "${RED}Please ensure your home directory is properly configured.${NC}"
    exit 1
  fi
  if [ -f /usr/local/bin/fish ]; then
    echo -e "${YELLOW}fish is already installed in /usr/local/bin.${NC}"
    read -r -p "Do you want to remove the existing fish-shell installation? [y/N]: " response </dev/tty
    case "$response" in
    [yY])
      echo -e "${YELLOW}Removing existing fish-shell...${NC}"
      sudo rm /usr/local/bin/fish
      rm -rf "$HOME/.config/fish"
      revert_fish_changes
      restore_user_shell
      echo -e "${GREEN}Fish shell completely removed and system restored.${NC}"
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
