FROM ubuntu:noble@sha256:b59d21599a2b151e23eea5f6602f4af4d7d31c4e236d22bf0b62b86d2e386b8f

ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ=Etc/UTC

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  mmdebstrap \
  squashfs-tools \
  sudo \
  tree \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /working \
  # mmdebstrap blows up with dash, so we revert to bash
  && rm /usr/bin/sh \
  && ln -s /usr/bin/bash /usr/bin/sh

WORKDIR /working