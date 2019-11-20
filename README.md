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

```
git clone https://github.com/opinkerfi/docker-adagios-rpm.git
cd docker-adagios-rpm
docker build -t adagios_systemd_image .
docker run --cap-add=SYS_ADMIN --name adagios  -v /sys/fs/cgroup:/sys/fs/cgroup -p 8080:80 -d adagios_systemd_image
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
