FROM ubuntu:resolute@sha256:678c6550cc43645e08669028bc177f50be4e7c5b8cca677067b1914d4afc7a03

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