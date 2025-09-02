# Roon Bridge in Docker

Roon Bridge in a Docker container. Supports aarch64 (armv8), aarch32 (armv7hf) and amd64 targets.

## Features

- Downloads and installs latest Roon Bridge on first container start
- Subsequent in-app Roon Bridge upgrades persist
- Audio output to USB DAC devices
- Persistent cache
- Secure execution (unprivileged execution, macvlan network)

## Getting Started

The following steps will work in most configurations and supports all features.

Install audio packages into the host:

```bash
apt install alsa-utils libasound2 libasound2-data libasound2-plugins
```

Create persistent docker volumes and a directory for local audio files:

```bash
docker volume create roon-bridge-data
docker volume create roon-bridge-cache
```

Run the docker container:

```bash
AUDIO_GID=$(getent group audio | cut -d: -f3)
docker run \
  --name roon-bridge \
  --detach \
  --volume roon-bridge-data:/opt/RoonBridge \
  --volume roon-bridge-cache:/var/roon \
  --network host \
  --restart unless-stopped \
  --volume /run/udev:/run/udev:ro \
  --device /dev/bus/usb \
  --device /dev/snd \
  --group-add "${AUDIO_GID:-29}" \
  elgeeko/roon-bridge
```

View logs:

```bash
docker logs -f roon-bridge
```

If your bridge and its audio outputs are now discoverable in Roon, you're good to go!
What follows is a more detailed guide for advanced setups or customization.

## Run Options

### Run in host network (easiest, less secure)

This is the simplest way to run the docker container.

```bash
docker run \
  --name roon-bridge \
  --detach \
  --volume roon-bridge-data:/opt/RoonBridge \
  --volume roon-bridge-cache:/var/roon \
  --network host \
  --restart unless-stopped \
  elgeeko/roon-bridge
```

### Run in macvlan mode (more secure)

Run in an unprivileged container using macvlan network mode. Replace the subnet, gateway, IP address, and primary ethernet adapter to match your local network.

> [!NOTE]
> Macvlan generally does not work on wifi networks, and wired ethernet is required. This is a limitation of how
> most wifi adapters handle MAC addresses and frames.

Create docker macvlan network:

```bash
docker network create \
  --driver macvlan \
  --subnet 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  -o parent=eth0 \
  roon
```

Run the macvlan container:

```bash
AUDIO_GID=$(getent group audio | cut -d: -f3)
docker run \
  --name roon-bridge \
  --detach \
  --volume roon-bridge-data:/opt/RoonBridge \
  --volume roon-bridge-cache:/var/roon \
  --volume ~/roon/music:/music:ro \
  --network roon \
  --restart unless-stopped \
  --ip 192.168.1.2 \
  --volume /run/udev:/run/udev:ro \
  --device /dev/bus/usb \
  --device /dev/snd \
  --group-add "${AUDIO_GID:-29}" \
  elgeeko/roon-bridge
```

View logs:

```bash
docker logs -f roon-bridge
```

## Troubleshooting

If you're having network connectivity issues, issues discovering other devices, or issues finding your roon server,
try more permissive docker settings. Add one or more of the following to diagnose:

- `--cap-add SYS_ADMIN` - adds broad admin capabilities (mount/namespace/cgroup ops); helps if the container needs OS-level actions blocked by default confinement.
- `--security-opt apparmor:unconfined` - disables the AppArmor profile; helps when AppArmor denies access to devices/files (e.g., `/dev/snd`, `/run/udev`) or certain syscalls.
- `--privileged` - grants all capabilities and device access, bypassing LSM confinement; helps confirm isolation is the blocker (USB/udev/network), but use only as a last-resort diagnostic.

## Feature Details

### Use USB DACs connected to the host

Add the following arguments to the `docker run` command:  

- `--volume /run/udev:/run/udev:ro` - allow Roon see USB device changes (udev events)
- `--device /dev/bus/usb` - allow Roon to access USB devices
- `--device /dev/snd` - allow Roon to access ALSA devices
- `--group-add $(getent group audio | cut -d: -f3)` - add container user to host 'audio' group

### Synchronize filesystem and last.fm timestamps with your local timezone

Add the following arguments to the `docker run` command:

- `--env TZ=America/Los_Angeles` - set tzdata timezone (substitute yours)
- `--volume /etc/localtime:/etc/localtime:ro` - map local system clock to container clock

## Known Issues

- USB DACs connected to the system for the first time do not appear in Roon.
The workaround is to restart the container. Once the device has been initially
connected, disconnecting and reconnecting is reflected in Roon.
- Mounting network drives via cifs may require root access. The workaround is to
run the container with the `user=root` option in the `docker run` command.
- Fedora CoreOS sets a system parameter `ulimit` to a smaller value than Roon
requires. Add the following argument to the `docker run` command:
`--ulimit nofile=8192`

## Ports Used

The ports used by Roon are not well-documented. The following ports are documented in forums:

- `9003/udp` - multicast / discovery.
- `9093/udp` - reported by some users as required for discovery.
- `9100-9200/tcp` - Roon API and RAAT server. See [Roon API Connecton Refused Error](https://community.roonlabs.com/t/roon-api-on-build-880-connection-refused-error/181619/3).

## Building from the Dockerfile

```shell
docker build .
```

## Resources

- [elgeeko/roon-bridge](https://hub.docker.com/repository/docker/elgeeko/roon-bridge) on Docker Hub
- [elgeeko1/roon-bridge-docker](https://github.com/elgeeko1/roon-bridge-docker) on Github
- Ansible script to deploy the Roon Bridge image: https://github.com/elgeeko1/elgeeko1-roon-bridge-ansible
- Roon Labs Linux install instructions: https://help.roonlabs.com/portal/en/kb/articles/linux-install

### Related projects

- [elgeeko/roon-server](https://hub.docker.com/repository/docker/elgeeko/roon-server) on Docker Hub
- [elgeeko1/roon-server-docker](https://github.com/elgeeko1/roon-server-docker) on Github
- Ansible script to deploy the Roon Server image, as well as an optional Samba server for network sharing of a local music library: [elgeeko1/elgeeko1-roon-server-ansible](https://github.com/elgeeko1/elgeeko1-roon-server-ansible)
