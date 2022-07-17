FROM ubuntu:20.04
LABEL maintainer="https://github.com/elgeeko1"

USER root

# Roon documented ports
#  - multicast (discovery?)
EXPOSE 9003/udp
#  - Roon Display
EXPOSE 9100/tcp
#  - RAAT
EXPOSE 9100-9200/tcp
#  - Roon events from cloud to core (websocket?)
EXPOSE 9200/tcp

# ports experimentally determined; or, documented
# somewhere and source forgotten; or, commented
# in a forum without explanation. I swear I know
# what these ports do but I've run out of space
# in the margin to write the solution. Either way
# there are no other services running in the
# container that should bind to these ports,
# so exposing them shouldn't pose a security risk.
EXPOSE 9001-9002/tcp
EXPOSE 49863/tcp
EXPOSE 52667/tcp
EXPOSE 52709/tcp
EXPOSE 63098-63100/tcp

# URI from which to download RoonBridge build
ENV ROON_PACKAGE_URI=http://download.roonlabs.com/builds/RoonBridge_linuxx64.tar.bz2

# Preconfigure debconf for non-interactive installation - otherwise complains about terminal
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
ARG DEBIAN_FRONTEND=noninteractive
ENV DISPLAY localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
	&& dpkg-divert --local --rename --add /sbin/initctl \
	&& ln -sf /bin/true /sbin/initctl \
	&& echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# set timezone. change to match your local zone.
# matching container to host timezones synchronizes
# last.fm posts, filesystem write times, and user
# expectations for times shown in the Roon client.
ARG TIMEZONE=America/Los_Angeles
ENV TIMEZONE=${TIMEZONE}
RUN apt-get update -q \
  && apt-get install --no-install-recommends -y -q tzdata \
  && echo "${TIMEZONE}" > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata \
  && apt-get -q -y clean \
  && rm -rf /var/lib/apt/lists/*

# install Roon prerequisites:
#  - Roon requirements: libasound2 libicu66
#  - Roon play to local audio device: alsa
#  - Docker healthcheck: curl
#  - Roon build download & extraction: wget bzip2
#  - Query USB devices inside Docker container: usbutils udev
RUN apt-get update -q \
  && apt-get install --no-install-recommends -y -q \
    libasound2 \
    libicu66 \
    alsa \
    curl \
    wget \
    bzip2 \
    usbutils \
    udev \
  && apt-get -q -y clean \
  && rm -rf /var/lib/apt/lists/*

# Download RoonBridge package.
# Disabled, since Roon license does not permit redistribution.
# Re-enable for local builds, or leave out and Roon will be
# installed when the container is first run.
# RUN curl ${ROON_PACKAGE_URI} | tar -xvj -C /opt

# non-root container user.
# you may want to randomize the UID to prevent
# accidental collisions with the host filesystem;
# however, this may prevent the container from
# accessing network shares that are not public,
# or if the RoonBridge build is mapped in from
# the host filesystem.
ARG CONTAINER_USER=roon
ARG CONTAINER_USER_UID=1000
RUN adduser --disabled-password --gecos "" --uid ${CONTAINER_USER_UID} ${CONTAINER_USER} \
  && mkdir -p /opt/RoonBridge \
  && chown -R ${CONTAINER_USER} /opt/RoonBridge \
  && chgrp -R ${CONTAINER_USER} /opt/RoonBridge \
  && mkdir -p /var/roon \
  && chown -R ${CONTAINER_USER} /var/roon \
  && chgrp -R ${CONTAINER_USER} /var/roon

COPY app/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ${CONTAINER_USER}

# persistent cache
VOLUME ["/var/roon"]
# optional: volume for RoonBridge build
# use for version upgrades to persist
VOLUME ["/opt/RoonBridge"]

# entrypoint
# set environment variables consumed by Roon
# startup script
ENV ROON_DATAROOT=/var/roon
ENV ROON_ID_DIR=/var/roon
ENTRYPOINT ["/entrypoint.sh"]
