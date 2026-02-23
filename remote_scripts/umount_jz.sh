#!/bin/bash

# Source mount_fct.sh to use unmount_remote_dir()
source "$(dirname "$0")/mount_fct.sh"

# Unmount directories from Jean-Zay

LOCAL_DIR=$HOME'/jean-zay_linkhome'
unmount_local_dir $LOCAL_DIR

LOCAL_DIR=$HOME'/jean-zay_lustre'
unmount_local_dir $LOCAL_DIR

echo "Jean-Zay directories unmounted."
echo ""
