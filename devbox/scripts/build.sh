# Check inside devbox shell
if [[ ! $DEVBOX_SHELL_ENABLED -eq 1 ]]; then
    echo "Value of \$DEVBOX_SHELL_ENABLED is: $DEVBOX_SHELL_ENABLED"
    echo "This script must be run inside a devbox shell"
    exit 1
fi
echo "continuing..."

mkdir -p -v $JULES_BUILD_DIR

fcm make -f $JULES_ROOT/etc/fcm-make/make.cfg -C $JULES_BUILD_DIR --new
