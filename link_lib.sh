#!/bin/bash

# This script finds the MergedDir of a Docker container and creates multiple symlinks.

# --- Configuration ---
# Define sources as an array. Each element is "source_subdirectory target_filename".
# The source_subdirectory is the path inside the container's filesystem.
# The target_filename will be created as a symlink under LINK_TARGET_DIR.
SOURCES=(
    "/usr/local/sysroot/usr/include sysroot_include"
    "/usr/local/include include"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Main Logic ---

# Determine target directory from argument or user prompt
if [ -n "$1" ]; then
    LINK_TARGET_DIR="$1"
    echo -e "Using target directory from argument: ${YELLOW}$LINK_TARGET_DIR${NC}"
else
    # Use -e with read -p to interpret color codes
    read -p "$(echo -e "Enter target directory [${YELLOW}/tmp/syno_include${NC}]: ")" user_input </dev/tty
    # Use the user's input, or the default if the input is empty
    LINK_TARGET_DIR="${user_input:-/tmp/syno_include}"
fi

# Get running container names into an array
mapfile -t running_containers < <(docker ps --format "{{.Names}}")

# Check if any containers are running
if [ ${#running_containers[@]} -eq 0 ]; then
    echo -e "${RED}Error: No running Docker containers found.${NC}"
    exit 1
fi

# Ask user to select a container
echo -e "${YELLOW}Please select a container to link libraries from:${NC}"
select container_choice in "${running_containers[@]}"; do
    if [[ -n "$container_choice" ]]; then
        CONTAINER_NAME="$container_choice"
        break
    else
        echo -e "${RED}Invalid selection. Please try again.${NC}"
    fi
done </dev/tty

echo -e "Inspecting container: ${YELLOW}$CONTAINER_NAME${NC}"

# Get the MergedDir path from docker inspect
MERGED_DIR=$(docker inspect -f '{{.GraphDriver.Data.MergedDir}}' "$CONTAINER_NAME")

# Check if the command succeeded and returned a path
if [ -z "$MERGED_DIR" ]; then
    echo -e "${RED}Error: Could not find MergedDir for container '$CONTAINER_NAME'.${NC}"
    echo -e "${RED}Please ensure the container exists and is running.${NC}"
    exit 1
fi

echo -e "Found MergedDir: ${GREEN}$MERGED_DIR${NC}"

# Create the target directory if it doesn't exist
echo -e "Ensuring target directory exists: ${YELLOW}$LINK_TARGET_DIR${NC}"
mkdir -p "$LINK_TARGET_DIR"

# Loop through the sources and create a symlink for each
echo -e "${GREEN}--- Starting linking process ---${NC}"

for source_entry in "${SOURCES[@]}"; do
    # Use read to safely parse the entry into two variables
    read -r source_subdir target_filename <<<"$source_entry"

    # Define the full source and target paths
    full_source_path="$MERGED_DIR/${source_subdir#/}"
    full_link_target="$LINK_TARGET_DIR/$target_filename"

    # Create the symbolic link
    ln -sfn "$full_source_path" "$full_link_target"

    # Verify the link was created and points to the correct source
    if [ -L "$full_link_target" ] && [ "$(readlink "$full_link_target")" = "$full_source_path" ]; then
        echo -e "${GREEN}✔${NC} Linked ${YELLOW}${target_filename}${NC} -> ${full_source_path}"
    else
        echo -e "${RED}✖${NC} Failed to link ${YELLOW}${target_filename}${NC}"
    fi
done

echo -e "${GREEN}--- Linking process complete ---${NC}"
