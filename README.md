## About

A comprehensive guide for collecting, and exporting telemetry data (metrics, logs, and traces) from Docker Swarm environment can be found at [swarmlibs/dockerswarm-monitoring-guide](https://github.com/swarmlibs/dockerswarm-monitoring-guide).

A Docker Stack deployment for the monitoring suite for Docker Swarm includes (Grafana, Prometheus, cAdvisor, Node exporter and Blackbox prober exporter)

> [!IMPORTANT]
> This project is a work in progress and is not yet ready for production use.
> But feel free to test it and provide feedback.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/swarmlibs/prometheus/assets/4363857/de6989e9-4a01-4a51-929a-677093c4a07f">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/swarmlibs/prometheus/assets/4363857/935760e1-7493-40d0-acd7-8abae1b7ced8">
  <img src="https://github.com/swarmlibs/prometheus/assets/4363857/935760e1-7493-40d0-acd7-8abae1b7ced8">
</picture>

**Table of Contents**:
- [About](#about)
- [Stacks](#stacks)
- [Pre-requisites](#pre-requisites)
- [Getting Started](#getting-started)
  - [Deploy using `promstack`](#deploy-using-promstack)
  - [Remove using `promstack`](#remove-using-promstack)

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

### Deploy using `promstack`

```sh
./promstack deploy
```

### Remove using `promstack`

```sh
./promstack remove
```

---

> [!IMPORTANT]
> This project is a work in progress and is not yet ready for production use.
> But feel free to test it and provide feedback.
