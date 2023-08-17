FROM ubuntu:22.04@sha256:56887c5194fddd8db7e36ced1c16b3569d89f74c801dc8a5adbf48236fb34564

# Note https://github.com/firecracker-microvm/firecracker/blob/main/resources/chroot.sh will ultimately run inside
# of this container, and will install more packages

RUN apt update && \
    apt install -y udev systemd-sysv openssh-server iproute2 curl socat python3-minimal iperf3 iputils-ping fio kmod

CMD ["/bin/bash"]
