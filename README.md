# Roon Bridge in Docker
Roon Bridge in a docker container.

### Features
- Downloads and installs latest Roon Bridge on first container start
- Audio output to USB DAC devices
- Local timezone support for accurate last.fm tagging
- Persistent cache
- Secure execution (unprivileged execution, macvlan network)
  - Privileged execution mode and host network are supported

# Running

## Install host prerequisites
Install the following audio packages into your host:
```sh
apt-get install alsa-utils libasound2 libasound2-data libasound2-plugins
```

### Create persistent data volumes
Create persistent docker volumes to retain the binary installation of
Roon Bridge and its configuration across restarts of the service.

Create the persistent docker volumes:
```sh
docker volume create roon-bridge-data
docker volume create roon-bridge-cache
```

## Option 1: Run in least secure mode (easiest)
Run using privileged execution mode and host network mode:
```sh
docker run \
  --name roon-bridge \
  --volume roon-bridge-data:/opt/RoonBridge \
  --volume roon-bridge-cache:/var/roon \
  --network host \
  --privileged \
  elgeeko/roon-bridge
```

## Option 2: Run in macvlan mode (more secure)
Run in an unprivileged container using macvlan network mode.
Replace the subnet, gateway and IP address to match your local network.

### Create docker macvlan network
```sh
docker network create \
  --driver macvlan \
  --subnet 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  -o parent=eth0 \
  roon
```

### Run using unprivileged execution mode and macvlan network mode
```sh
docker run \
  --name roon-bridge \
  --volume roon-bridge-data:/opt/RoonBridge \
  --volume roon-bridge-cache:/var/roon \
  --publish-all \
  --network roon \
  --ip 192.168.1.2 \
  elgeeko/roon-bridge
```

# Additional functionality

### Use USB DACs connected to the host
Add the following arguments to the `docker run` command:  
`--volume /run/udev:/run/udev:ro` - allow Roon to enumerate USB devices  
`--device /dev/bus/usb` - allow Roon to access USB devices (`/dev/usbmon0` for Fedora)   
`--device /dev/snd` - allow Roon to access ALSA devices   
`--group-add $(getent group audio | cut -d: -f3)` - add container user to host 'audio' group

### Synchronize filesystem and last.fm timestamps with your local timezone
Add the following arguments to the `docker run` command:  
`--volume /etc/localtime:/etc/localtime:ro` - map local system clock to container clock  
`--volume /etc/timezone:/etc/timezone:ro` - map local system timezone to container timezone  

# Known Issues
- USB DACs connected to the system for the first time do not appear in Roon.
The workaround is to restart the container. Once the device has been initially
connected, disconnecting and reconnecting is reflected in Roon.
- Fedora CoreOS sets a system paramenter `ulimit` to a smaller value than Roon
requires. Add the following argument to the `docker run` command:   
`--ulimit nofile=8192`

# Building from the Dockerfile
`docker build .`

# Resources
- [elgeeko/roon-bridge](https://hub.docker.com/repository/docker/elgeeko/roon-bridge) on Docker Hub
- Ansible script to deploy the Roon Bridge image: https://github.com/elgeeko1/elgeeko1-roon-bridge-ansible
- Roon Labs Linux install instructions: https://help.roonlabs.com/portal/en/kb/articles/linux-install
