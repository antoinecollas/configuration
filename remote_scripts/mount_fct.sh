# Function to mount remote directory using sshfs
mount_remote_dir() {
    local remote_dir=$1
    local local_dir=$2
    local remote_computer=$3

    echo "\$SSHFS_OPTIONS: $SSHFS_OPTIONS"
    echo "\$REMOTE_COMPUTER: $remote_computer"
    echo "\$remote_dir: $remote_dir"
    echo "\$local_dir: $local_dir"

    # Ensure mount point exists
    if [ ! -d "$local_dir" ]; then
        echo "Creating local mount point: $local_dir"
        mkdir -p "$local_dir"
    fi

    # Check if already mounted
    if mount | grep -q "$local_dir"; then
        echo "$local_dir is already mounted. Skipping."
        return 0
    fi

    # Mount with refined options
    # if ! sshfs -o reconnect,auto_cache,default_permissions,uid=$(id -u),gid=$(id -g),allow_other $SSHFS_OPTIONS $remote_computer:$remote_dir $local_dir; then
    if ! sshfs -o reconnect,default_permissions,uid=$(id -u),gid=$(id -g),allow_other -o iosize=1048576 "$remote_computer:$remote_dir" "$local_dir"; then
        echo "Failed to mount $remote_dir at $local_dir"
        return 1
    fi

    echo "$remote_dir mounted at: $local_dir"
    echo ""
    return 0
}

# Function to unmount a local directory
unmount_local_dir() {
    local local_dir=$1

    echo "Attempting to unmount: $local_dir"
    sudo umount -f $local_dir
    if [ $? -eq 0 ]; then
        echo "Unmounted: $local_dir"
    else
        echo "Failed to unmount: $local_dir"
    fi
    echo ""
    return 0
}

