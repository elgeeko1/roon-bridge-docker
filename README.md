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

## Install prerequisites on the host
Install the following audio packages into your host:
```sh
apt-get install alsa-utils libasound2 libasound2-data libasound2-plugins
```

## Create persistent data directories in host filesystem
The commands below require the following folders exist in your host filesystem:
- `data` on your host which will be used for Roon's persistent storage. Example: `/home/myuser/roon/data`.

Create the persistent data directories in the host filesystem:
```sh
mkdir -p ~/roon
mkdir -p ~/roon/data
```

## Option 1: Run in least secure mode (easiest)
Run using privileged execution mode and host network mode:
```sh
docker run \
  --name roon-bridge \
  --volume ~/roon/data:/var/roon \
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
  --subnet 192.168.1.0 \
  --gateway 192.168.1.1 \
  -o parent=eth0 \
  roon
```

### Run using unprivileged execution mode and macvlan network mode
```sh
docker run \
  --name roon-bridge \
  --publish_all \
  --volume ~/roon/data:/var/roon \
  --network roon \
  --ip 192.168.1.2 \
  elgeeko/roon-bridge
```

# Additional functionality

### Use USB DACs connected to the host
Add the following arguments to the `docker run` command:  
`--volume /usr/share/alsa:/usr/share/alsa` - allow Roon to access ALSA cards  
`--volume /run/udev:/run/udev:ro` - allow Roon to enumerate USB devices  
`--device /dev/bus/usb` - allow Roon to access USB devices  
`--device /dev/snd` - allow Roon to access ALSA devices  

### Synchronize filesystem and last.fm timestamps with your local timezone
Add the following arguments to the `docker run` command:  
`--volume /etc/localtime:/etc/localtime:ro` - map local system clock to container clock  
`--volume /etc/timezone:/etc/timezone:ro` - map local system timezone to container timezone  

# Known Issues
- USB DACs connected to the system for the first time do not appear in Roon.
The workaround is to restart the container. Once the device has been initially
connected, disconnecting and reconnecting is reflected in Roon.

# Building from the Dockerfile
`docker build .`

# Resources
- [elgeeko/roon-bridge](https://hub.docker.com/repository/docker/elgeeko/roon-bridge) on Docker Hub
- Ansible script to deploy the Roon Bridge image: https://github.com/elgeeko1/elgeeko1-roon-bridge-ansible
- Roon Labs Linux install instructions: https://help.roonlabs.com/portal/en/kb/articles/linux-install
