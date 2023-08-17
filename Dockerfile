FROM ubuntu:latest

RUN apt update && \
    apt install -y \
        sudo \
        git

RUN useradd builder -G 0 && \
    mkdir -p /home/builder && \
    chown -R builder:0 /home/builder && \
    chmod -R g=u /home/builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /home/builder

COPY --chown=root:0 ./build.sh ./
COPY --chown=root:0 ./versions ./versions

USER builder

CMD ["./build.sh"]
