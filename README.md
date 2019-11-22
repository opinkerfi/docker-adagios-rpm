# docker-adagios-rpm
Docker image for Adagios built from rpms (Naemon-Adagios)

[![Docker Stars](https://img.shields.io/docker/stars/opinkerfi/adagios-rpm.svg)]()
[![Docker Pulls](https://img.shields.io/docker/pulls/opinkerfi/adagios-rpm.svg)]()
[![GitHub tag](https://img.shields.io/github/tag/opinkerfi/adagios-rpm.svg)]()
[![GitHub release](https://img.shields.io/github/release/opinkerfi/adagios-rpm.svg)]()

## Usage

```
docker create \
  --name=my-adagios \
  -p 80:80 \
  opinkerfi/adagios-rpm
```

Log in with user `thrukadmin` and password `thrukadmin`

## Building

### Docker
```
git clone https://github.com/opinkerfi/docker-adagios-rpm.git
cd docker-adagios-rpm
docker build -t adagios_systemd_image .
docker run --cap-add=SYS_ADMIN --name adagios  -v /sys/fs/cgroup:/sys/fs/cgroup -p 8080:80 -d adagios_systemd_image
```
### Podman
```shell
# If SELinux is enabled on your system, you must turn on the container_manage_cgroup boolean 
# to run containers with systemd 
setsebool -P container_manage_cgroup on
git clone https://github.com/opinkerfi/docker-adagios-rpm.git
cd docker-adagios-rpm
podman build -t adagios_systemd_image .
podman run --name adagios -p 8080:80 -d adagios_systemd_image
```

#### Running podman container from systemd
See [RUNNING CONTAINERS AS SYSTEMD SERVICES WITH PODMAN](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/managing_containers/running_containers_as_systemd_services_with_podman)
```ini
[Unit]
Description=Adagios container

[Service]
Restart=always
ExecStart=/usr/bin/podman start -a adagios
ExecStop=/usr/bin/podman stop -t 2 adagios

[Install]
WantedBy=local.target
```
Then you should be able to access http://localhost:8080
Log in with user `thrukadmin` and password `thrukadmin`

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. 
For example with a port -p external:internal - what this shows is the port mapping from internal to external of the container.
So -p 8080:80 would expose port 80 from inside the container to be accessible from the host's IP on port 8080
http://192.168.x.x:8080 would show you what's running INSIDE the container on port 80.

* `-p 80` - Port for adagios webui

For shell access whilst the container is running do `docker exec -it my-adagios /bin/bash`.
