## About

A Docker Stack deployment for the monitoring suite for Docker Swarm includes (Grafana, Prometheus, cAdvisor, Node exporter and Blackbox prober exporter)

> [!IMPORTANT]
> This project is a work in progress and is not yet ready for production use.
> But feel free to test it and provide feedback.

- [About](#about)
- [Stacks](#stacks)
- [Pre-requisites](#pre-requisites)
- [Getting Started](#getting-started)
  - [Deploy `promstack`](#deploy-promstack)
  - [Remove `promstack`](#remove-promstack)
- [Configure the Docker daemon](#configure-the-docker-daemon)

## Stacks

- [cadvisor](https://github.com/google/cadvisor): Analyzes resource usage and performance characteristics of running containers.
- [grafana](https://github.com/swarmlibs/grafana): A custom Grafana Dashboard for Docker Swarm.
- [node-exporter](https://github.com/swarmlibs/node-exporter): A custom Node exporter for Docker Swarm.
- [prometheus](https://github.com/swarmlibs/prometheus): The Prometheus monitoring system and time series database customized for Docker Swarm.

## Pre-requisites

- Docker running Swarm mode
- A Docker Swarm cluster with at least 3 nodes
- Configure Docker daemon to expose metrics for Prometheus

## Getting Started

To get started, clone this repository to your local machine:

```sh
git clone https://github.com/swarmlibs/promstack.git
# or
gh repo clone swarmlibs/promstack
```

Navigate to the project directory:

```sh
cd promstack
```

Create user-defined networks:

```sh
docker network create --scope=swarm --driver=overlay --attachable prometheus
docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork
```

* The `prometheus` network is used to perform service discovery for Prometheus scrape configs.
* The `prometheus_gwnetwork` network is used for the internal communication between the Prometheus Server, exporters and other agents.

### Deploy `promstack`

```sh
# TBD
```

### Remove `promstack`

```sh
# TBD
```

## Configure the Docker daemon

To configure the Docker daemon as a Prometheus target, you need to specify the metrics-address in the daemon.json configuration file. This daemon expects the file to be located at one of the following locations by default. If the file doesn't exist, create it.

* **Linux**: `/etc/docker/daemon.json`
* **Docker Desktop**: Open the Docker Desktop settings and select Docker Engine to edit the file.

Add the following configuration:

```json
{
  "metrics-addr": "0.0.0.0:9323"
}
```

Save the file, or in the case of Docker Desktop for Mac or Docker Desktop for Windows, save the configuration. Restart Docker.

The Docker Engine now exposes Prometheus-compatible metrics on port `9323` on all interfaces. For more information on configuring the Docker daemon, see the [Docker documentation](https://docs.docker.com/config/daemon/prometheus/).
