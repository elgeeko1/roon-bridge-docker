#!/bin/bash

# SPDX-FileCopyrightText: (c) 2022-2025 Jeff C. Jensen
# SPDX-License-Identifier: MIT

# prefer userland package arch (Debian/Ubuntu); fallback to kernel arch
if command -v dpkg >/dev/null 2>&1; then
  arch="$(dpkg --print-architecture)"          # amd64 | arm64 | armhf | ...
else
  arch="$(uname -m)"                            # x86_64 | aarch64 | armv7l | ...
fi

case "$arch" in
  amd64|x86_64)
    ROON_PACKAGE_URI="https://download.roonlabs.com/builds/RoonBridge_linuxx64.tar.bz2"
    ;;
  arm64|aarch64)
    ROON_PACKAGE_URI="https://download.roonlabs.com/builds/RoonBridge_linuxarmv8.tar.bz2"
    ;;
  armhf|armv7l|armv7hl|armv7)
    ROON_PACKAGE_URI="https://download.roonlabs.com/builds/RoonBridge_linuxarmv7hf.tar.bz2"
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

echo Starting RoonBridge as user `whoami`

# install Roon if not present
if [ ! -f /opt/RoonBridge/start.sh ]; then
  echo Downloading Roon Bridge from ${ROON_PACKAGE_URI}
  wget --progress=bar:force --tries=2 -O - ${ROON_PACKAGE_URI} | tar -xvj --overwrite -C /opt
  if [ $? != 0 ]; then
    echo Error: Unable to download Roon Bridge.
    exit 1
  fi
fi

echo Verifying Roon Bridge installation
/opt/RoonBridge/check.sh
retval=$?
if [ ${retval} != 0 ]; then
  echo Verification of Roon Bridge installation failed.
  exit ${retval}
fi

# start Roon Bridge
#
# since we're invoking from a script, we need to
# catch signals to terminate Roon nicely
/opt/RoonBridge/start.sh &
roon_start_pid=$!
trap 'kill -INT ${roon_start_pid}' SIGINT SIGQUIT SIGTERM
wait "${roon_start_pid}" # block until Roon terminates
retval=$?
exit ${retval}
