if [[ ! $DEVBOX_SHELL_ENABLED -eq 1 ]]; then
    echo "This script must be run inside a devbox shell"
    exit 1
fi
echo "Hello $USER"
