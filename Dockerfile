FROM ubuntu:noble@sha256:9c7f200c07e3d4a03e7249d2c16bf66a51120fb876aa2242cf31451412543289

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