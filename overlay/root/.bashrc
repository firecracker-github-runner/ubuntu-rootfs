# NOTE: It's important to continue on error, so that we always reboot
set -x

echo "Welcome to the container!"

# mount ramdisk at /working
mount -t tmpfs -o size=16G tmpfs /working

sudo -iu runner "cd /home/runner && ./init"

reboot