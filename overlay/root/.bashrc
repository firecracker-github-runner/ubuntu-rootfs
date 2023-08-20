# NOTE: It's important to continue on error, so that we always reboot
set -x

echo "Welcome to the container!"

su runner -c "cd /home/runner && ./init"

reboot