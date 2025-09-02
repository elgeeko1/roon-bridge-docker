# SPDX-FileCopyrightText: (c) 2021-2025 Jeff C. Jensen
# SPDX-License-Identifier: MIT

# syntax=docker/dockerfile:1

ARG BUILDKIT_SBOM_SCAN_CONTEXT=true
ARG BUILDKIT_SBOM_SCAN_STAGE=true
ARG BASEIMAGE=noble-20250716

##################
## base stage
##################
FROM ubuntu:${BASEIMAGE} AS base

USER root

# Preconfigure debconf for non-interactive installation - otherwise complains about terminal
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# configure python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# configure apt
RUN apt-get update -q
RUN apt-get install --no-install-recommends -y -q ca-certificates

# install prerequisites
# Roon prerequisites:
#  - Roon requirements: libasound2-dev
#  - Roon play to local audio device: alsa
#  - Query USB devices inside Docker container: usbutils udev libudev1
RUN apt-get install --no-install-recommends -y -q libasound2-dev alsa
RUN apt-get install --no-install-recommends -y -q usbutils udev libudev1
# app prerequisites
#  - App entrypoint downloads Roon bridge: wget bzip2
RUN apt-get install --no-install-recommends -y -q wget bzip2

# apt cleanup
RUN apt-get autoremove -y -q
RUN apt-get -y -q clean
RUN rm -rf /var/lib/apt/lists/*

####################
## application stage
####################
FROM scratch
COPY --from=base / /

LABEL maintainer="elgeeko1"
LABEL source="https://github.com/elgeeko1/roon-bridge-docker"
LABEL org.opencontainers.image.title="Roon Bridge"
LABEL org.opencontainers.description="Roon Bridge"
LABEL org.opencontainers.image.authors="Jeff C. Jensen <11233838+elgeeko1@users.noreply.github.com>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="1.1.0"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/elgeeko/roon-bridge"
LABEL org.opencontainers.image.source="https://github.com/elgeeko1/roon-bridge-docker"

# Roon documented ports
#  - multicast (discovery?)
EXPOSE 9003/udp
#  - Roon API and RAAT server
#    see https://community.roonlabs.com/t/roon-api-on-build-880-connection-refused-error/181619/3
#    - RAAT server typically :9200
EXPOSE 9100-9200/tcp
EXPOSE 9093/udp

USER root

# non-root container user.
# you may want to randomize the UID to prevent
# accidental collisions with the host filesystem;
# however, this may prevent the container from
# accessing network shares that are not public,
# or if the RoonServer build is mapped in from
# the host filesystem.
ARG CONTAINER_USER=ubuntu
ARG CONTAINER_USER_UID=1000
RUN if [ "${CONTAINER_USER}" != "ubuntu" ]; \
	then useradd \
		--uid ${CONTAINER_USER_UID} \
		--user-group \
		${CONTAINER_USER}; \
	fi

# add container user to audio group
RUN usermod -a -G audio ${CONTAINER_USER}

# copy application files
COPY --chmod=0755 app/entrypoint.sh /entrypoint.sh
COPY README.md /README.md

# configure filesystem
## map a volume to this location to retain Roon Bridge data
RUN mkdir -p /opt/RoonBridge \
	&& chown ${CONTAINER_USER}:${CONTAINER_USER} /opt/RoonBridge
## map a volume to this location to retain Roon Bridge cache
RUN mkdir -p /var/roon \
	&& chown ${CONTAINER_USER}:${CONTAINER_USER} /var/roon

USER ${CONTAINER_USER}

# entrypoint
# set environment variables consumed by Roon
# startup script
ENV ROON_DATAROOT=/var/roon
ENV ROON_ID_DIR=/var/roon
ENTRYPOINT ["/entrypoint.sh"]
