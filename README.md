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
  - [Deploy `promstack`](#deploy-promstack)
  - [Remove `promstack`](#remove-promstack)
- [Configurations](#configurations)
  - [Prometheus](#prometheus)

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
# This ingress network is used by Blackbox exporter to perform network probes
docker network create --scope=swarm --driver=overlay --attachable public

# The `prometheus` network is used to perform service discovery for Prometheus scrape configs.
docker network create --scope=swarm --driver=overlay --attachable prometheus

# The `prometheus_gwnetwork` network is used for the internal communication between the Prometheus Server, exporters and other agents.
docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork
```

* The `public` network is used as 3rd-party ingress.
* The `prometheus` network is used to perform service discovery for Prometheus scrape configs.
* The `prometheus_gwnetwork` network is used for the internal communication between the Prometheus Server, exporters and other agents.

The `prometheu` and `grafana` services are deployed on nodes that match the following labels:

```sh
docker node update --label-add "io.promstack.prometheus=true" <node-id>
docker node update --label-add "io.promstack.grafana=true" <node-id>
```

See [Control service placement](https://docs.docker.com/engine/swarm/services/#control-service-placement) for more information.

### Deploy `promstack`

```sh
make deploy
```

### Remove `promstack`

```sh
make remove
```

## Configurations

TBD

### Prometheus

You can apply custom configurations to Prometheus via Environment variables by running `docker service update` command on `promstack_prometheus-config` service:

```sh
# Register the Alertmanager service address
docker service update --env-add PROMETHEUS_SCRAPE_INTERVAL=15s promstack_prometheus_config

# Remove the Alertmanager service address
docker service update --env-rm PROMETHEUS_SCRAPE_INTERVAL promstack_prometheus_config
```

**Global**:
- `PROMETHEUS_SCRAPE_INTERVAL`: The scrape interval for Prometheus, default is `10s`
- `PROMETHEUS_SCRAPE_TIMEOUT`: The scrape timeout for Prometheus, default is `5`
- `PROMETHEUS_EVALUATION_INTERVAL`: The evaluation interval for Prometheus, default is `1m`

**Clustering**:
- `PROMETHEUS_CLUSTER_NAME`: The cluster name for Prometheus, default is `promstack`
- `PROMETHEUS_CLUSTER_REPLICA`: The cluster replica for Prometheus, default is `1`

**Alertmanager**:
- `PROMETHEUS_ALERTMANAGER_ADDR`: The Alertmanager service address
- `PROMETHEUS_ALERTMANAGER_SERVICE_PORT`: The Alertmanager service port, default is `9093`

---

> [!IMPORTANT]
> This project is a work in progress and is not yet ready for production use.
> But feel free to test it and provide feedback.
