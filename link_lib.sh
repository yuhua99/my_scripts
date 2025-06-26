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

# --- Main Logic ---

# Determine target directory from argument or user prompt
if [ -n "$1" ]; then
    LINK_TARGET_DIR="$1"
    echo "Using target directory from argument: $LINK_TARGET_DIR"
else
    read -p "Enter target directory [/tmp/syno_include]: " user_input
    # Use the user's input, or the default if the input is empty
    LINK_TARGET_DIR="${user_input:-/tmp/syno_include}"
fi

# Get running container names into an array
mapfile -t running_containers < <(docker ps --format "{{.Names}}")

# Check if any containers are running
if [ ${#running_containers[@]} -eq 0 ]; then
    echo "Error: No running Docker containers found."
    exit 1
fi

# Ask user to select a container
echo "Please select a container to link libraries from:"
select container_choice in "${running_containers[@]}"; do
    if [[ -n "$container_choice" ]]; then
        CONTAINER_NAME="$container_choice"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

echo "Inspecting container: $CONTAINER_NAME"

# Get the MergedDir path from docker inspect
MERGED_DIR=$(docker inspect -f '{{.GraphDriver.Data.MergedDir}}' "$CONTAINER_NAME")

# Check if the command succeeded and returned a path
if [ -z "$MERGED_DIR" ]; then
    echo "Error: Could not find MergedDir for container '$CONTAINER_NAME'."
    echo "Please ensure the container exists and is running."
    exit 1
fi

echo "Found MergedDir: $MERGED_DIR"

# Create the target directory if it doesn't exist
echo "Ensuring target directory exists: $LINK_TARGET_DIR"
mkdir -p "$LINK_TARGET_DIR"

# Loop through the sources and create a symlink for each
for source_entry in "${SOURCES[@]}"; do
    # Use read to safely parse the entry into two variables
    read -r source_subdir target_filename <<<"$source_entry"

    # Define the full source and target paths
    # Note: We remove any leading slash from source_subdir to correctly join with MERGED_DIR
    full_source_path="$MERGED_DIR/${source_subdir#/}"
    full_link_target="$LINK_TARGET_DIR/$target_filename"

    echo "---"
    echo "Linking $full_source_path"
    echo "     to $full_link_target"

    # Create the symbolic link. -s for symbolic, -f to overwrite, -n to treat destination as a normal file
    ln -sfn "$full_source_path" "$full_link_target"

    # Verify the link was created
    if [ -L "$full_link_target" ]; then
        echo "Successfully created symbolic link:"
        ls -l "$full_link_target"
    else
        echo "Error: Failed to create symbolic link for '$target_filename'."
    fi
done

echo "---"
echo "Linking process complete."
