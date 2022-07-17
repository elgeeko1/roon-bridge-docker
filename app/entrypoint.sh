#!/bin/bash

ROON_PACKAGE_URI=${ROON_PACKAGE_URI-"http://download.roonlabs.com/builds/RoonBridge_linuxx64.tar.bz2"}

# install Roon if not present
if [ ! -f /opt/RoonBridge/start.sh ]; then
  echo Downloading Roon Bridge from ${ROON_PACKAGE_URI}
  wget \
    --show-progress \
    --tries=2 \
    -O /tmp/RoonBridge_linuxx64.tar.bz2 \
    ${ROON_PACKAGE_URI}
  if [ $? != 0 ]; then
    echo Error: Unable to download Roon Bridge.
    exit 1
  fi

  echo Extracting Roon Bridge
  tar -xvjf /tmp/RoonBridge_linuxx64.tar.bz2 -C /opt
  if [ $? != 0 ]; then
    echo Error: Unable to extract Roon Bridge.
    exit 2
  fi

  # cleanup
  rm /tmp/RoonBridge_linuxx64.tar.bz2
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
