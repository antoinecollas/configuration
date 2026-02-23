# Source mount_fct.sh to use mount_remote_dir()
source "$(dirname "$0")/mount_fct.sh"

# Jean-Zay cluster
USER='XXXX'
REMOTE_COMPUTER='jz'

# Mount $HOME
REMOTE_DIR='/lustre/fshomisc/home'
LOCAL_DIR=$HOME'/jean-zay_linkhome'
mount_remote_dir $REMOTE_DIR $LOCAL_DIR $REMOTE_COMPUTER

# Mount $WORK
REMOTE_DIR='/lustre'
LOCAL_DIR=$HOME'/jean-zay_lustre'
mount_remote_dir $REMOTE_DIR $LOCAL_DIR $REMOTE_COMPUTER

echo "Jean-Zay directories mounted."
echo ""
