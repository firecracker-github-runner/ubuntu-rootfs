FROM ubuntu:resolute@sha256:065aa8626841f16057b78b027b464cd59c4fac36c204c72dcbf48d66f5fa8a96

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