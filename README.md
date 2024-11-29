## About

A comprehensive guide for collecting, and exporting telemetry data (metrics, logs, and traces) from Docker Swarm environment can be found at [swarmlibs/dockerswarm-monitoring-guide](https://github.com/swarmlibs/dockerswarm-monitoring-guide).

A Docker Stack deployment for the monitoring suite for Docker Swarm includes (Grafana, Prometheus, cAdvisor, Node exporter and Blackbox prober exporter)

> [!IMPORTANT]
> This project is a work in progress and is not yet ready for production use.
> But feel free to test it and provide feedback.

**Table of Contents**:
- [About](#about)
- [Concepts](#concepts)
  - [Prometheus Server](#prometheus-server)
  - [Prometheus Agent](#prometheus-agent)
  - [Configuration providers and config reloader services](#configuration-providers-and-config-reloader-services)
- [Stacks](#stacks)
- [Pre-requisites](#pre-requisites)
- [Getting Started](#getting-started)
  - [Unattented deployment](#unattented-deployment)
  - [Manually deploy `promstack` stack](#manually-deploy-promstack-stack)
    - [Deploy stack](#deploy-stack)
    - [Remove stack](#remove-stack)
  - [Verify deployment](#verify-deployment)
- [Grafana](#grafana)
    - [Injecting Grafana Dashboards](#injecting-grafana-dashboards)
    - [Injecting Grafana Provisioning configurations](#injecting-grafana-provisioning-configurations)
- [Prometheus](#prometheus)
    - [Register services as Prometheus targets](#register-services-as-prometheus-targets)
    - [Register a custom scrape config](#register-a-custom-scrape-config)
  - [Configure Prometheus](#configure-prometheus)
    - [Environment variables](#environment-variables)
- [Services and Ports](#services-and-ports)
- [Troubleshooting](#troubleshooting)
  - [Grafana dashboards are not present](#grafana-dashboards-are-not-present)
  - [Promethues targets are not present](#promethues-targets-are-not-present)
- [License](#license)


## Concepts

This section covers some concepts that are important to understand for day to day Promstack usage and operation.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/59d6c0ec-d24a-443d-8cfe-4e85f296578b">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/4e17f0d7-22d1-44d7-9318-d5e58baf9580">
  <img src="https://github.com/user-attachments/assets/4e17f0d7-22d1-44d7-9318-d5e58baf9580">
</picture>

### Prometheus Server

The Prometheus server is the core component of the monitoring stack. It is responsible for collecting, storing and querying the metrics data. The Prometheus server is configured to receive remote write requests from the Prometheus agent.

### Prometheus Agent

By design, the Prometheus agent is deploy globally to all noded and configured to automatically discover services, tasks and scrape the metrics from those deployed within the node.

You can use Docker object labels in the deploy block to automagically register services as targets for Prometheus. It also configured with config provider and config reloader services.

See [Register services as Prometheus targets](#register-services-as-prometheus-targets) for more information.

**Prometheus Kubernetes compatible labels**

Here is a list of Docker Service/Task labels that are mapped to Kubernetes labels.

| Kubernetes   | Docker                                                        | Scrape config                    |
| ------------ | ------------------------------------------------------------- | -------------------------------- |
| `namespace`  | `__meta_dockerswarm_service_label_com_docker_stack_namespace` |                                  |
| `deployment` | `__meta_dockerswarm_service_name`                             |                                  |
| `pod`        | `dockerswarm_task_name`                                       | `dockerswarm/services`           |
| `service`    | `__meta_dockerswarm_service_name`                             | `dockerswarm/services-endpoints` |

* The **dockerswarm_task_name** is a combination of the service name, slot and task id.
* The task id is a unique identifier for the task. It depends on the mode of the deployement (replicated or global). If the service is replicated, the task id is the slot number. If the service is global, the task id is the node id.

### Configuration providers and config reloader services

The `grafana` and `prometheus` service requires extra services to operate, mainly for providing configuration files. There are two type of child services, a config provider and config reloader service.

Here an example visual representation of the services:

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/swarmlibs/prometheus-configs-provider/assets/4363857/5e790dd2-0d06-434a-98f7-a1e412388c96">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/swarmlibs/prometheus-configs-provider/assets/4363857/d439c204-fec4-492a-99f7-20df95ae1217">
  <img src="https://github.com/swarmlibs/prometheus-configs-provider/assets/4363857/d439c204-fec4-492a-99f7-20df95ae1217">
</picture>

We leverage the below services:
- [swarmlibs/prometheus-config-provider](https://github.com/swarmlibs/prometheus-config-provider)
- [swarmlibs/grafana-provisioning-config-reloader](https://github.com/swarmlibs/grafana-provisioning-config-reloader)
- [prometheus-operator/prometheus-config-reloader](https://github.com/prometheus-operator/prometheus-operator/tree/main/cmd/prometheus-config-reloader)

---

## Stacks

These are the services that are part of the stack:

- Blackbox exporter: https://github.com/prometheus/blackbox_exporter
- cAdvisor: https://github.com/google/cadvisor
- Grafana: https://github.com/grafana/grafana
- Node exporter: https://github.com/prometheus/node_exporter
- Prometheus: https://github.com/prometheus/prometheus
- Pushgateway: https://github.com/prometheus/pushgateway

## Pre-requisites

- Docker running Swarm mode
- A Docker Swarm cluster with at least 3 nodes
- Configure Docker daemon to expose metrics for Prometheus
- The official [swarmlibs](https://github.com/swarmlibs/swarmlibs) stack, this provided necessary services for other stacks operate.

## Getting Started

There are two ways to deploy the `promstack` stack:
- Unattented deployment
- Manually deploy `promstack` stack

The unattented deployment is the recommended way to deploy the stack. It will automatically create the necessary networks and deploy the stack to the Docker Swarm cluster.
The manual deployment is useful for debugging and troubleshooting the stack.

### Unattented deployment

To deploy the stack, you can use the following command:

```sh
$ docker run -it --rm \
    --name promstack \
    -v /var/run/docker.sock:/var/run/docker.sock \
    swarmlibs/promstack install
```

For more documentation, visit https://github.com/swarmlibs/docker-promstack.

### Manually deploy `promstack` stack

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
make stack-networks

# or run the following command to create the networks manually

docker network create --scope=swarm --driver=overlay --attachable public
docker network create --scope=swarm --driver=overlay --attachable prometheus
docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork
```

* This `public` network is used by Ingress service and Blackbox exporter to perform network probes
* The `prometheus` network is used to perform service discovery for Prometheus scrape configs.
* The `prometheus_gwnetwork` network is used for the internal communication between the Prometheus Server, exporters and other agents.

The `grafana` and `prometheus` service requires extra services to operate, mainly for providing configuration files. There are two type of child services, a config provider and config reloader service. In order to ensure placement of these services, you need to deploy the `swarmlibs` stack.

See https://github.com/swarmlibs/swarmlibs for more information.

#### Deploy stack

This will deploy the stack to the Docker Swarm cluster. Please ensure you have the necessary permissions to deploy the stack and the `swarmlibs` stack is deployed. See [Pre-requisites](#pre-requisites) for more information.

> [!IMPORTANT]
> It is important to note that the `promstack` is the default stack namespace for this deployment.  
> It is **NOT RECOMMENDED** to change the stack namespace as it may cause issues with the deployment.

```sh
make deploy
```

#### Remove stack

> [!WARNING]
> This will remove the stack and all the services associated with it. Use with caution.

```sh
make remove
```

### Verify deployment

To verify the deployment, you can use the following commands:

```sh
docker service ls --filter label=com.docker.stack.namespace=promstack

# NAME                                                 MODE         REPLICAS               IMAGE                                                           
# promstack_blackbox-exporter                          replicated   1/1 (max 1 per node)   prom/blackbox-exporter:v0.25.0                                  
# promstack_cadvisor                                   global       1/1                    gcr.io/cadvisor/cadvisor:v0.49.1                                
# promstack_grafana                                    replicated   1/1 (max 1 per node)   busybox:latest                                                  
# promstack_grafana-dashboard-provider                 global       1/1                    swarmlibs/prometheus-config-provider:0.1.0-rc.1                 
# promstack_grafana-provisioning-alerting-provider     global       1/1                    swarmlibs/prometheus-config-provider:0.1.0-rc.1                 
# promstack_grafana-provisioning-config-reloader       global       1/1                    swarmlibs/grafana-provisioning-config-reloader:0.1.0-rc.3       
# promstack_grafana-provisioning-dashboard-provider    global       1/1                    swarmlibs/prometheus-config-provider:0.1.0-rc.1                 
# promstack_grafana-provisioning-datasource-provider   global       1/1                    swarmlibs/prometheus-config-provider:0.1.0-rc.1                 
# promstack_grafana-server                             global       1/1                    grafana/grafana:11.3.0                                          
# promstack_node-exporter                              global       1/1                    prom/node-exporter:v1.8.1                                       
# promstack_prometheus                                 global       1/1                    swarmlibs/genconfig:0.1.0-rc.1                                  
# promstack_prometheus-agent                           global       1/1                    prom/prometheus:v3.0.0                                          
# promstack_prometheus-config-reloader                 global       1/1                    quay.io/prometheus-operator/prometheus-config-reloader:v0.74.0  
# promstack_prometheus-rule-provider                   global       1/1                    swarmlibs/prometheus-config-provider:0.1.0-rc.1                 
# promstack_prometheus-scrape-config-provider          global       1/1                    swarmlibs/prometheus-config-provider:0.1.0-rc.1                 
# promstack_prometheus-server                          replicated   1/1 (max 1 per node)   prom/prometheus:v3.0.0                                           
# promstack_prometheus-service-discovery               global       1/1                    swarmlibs/prometheus-service-discovery:0.1.0-rc.1               
# promstack_pushgateway                                replicated   1/1 (max 1 per node)   prom/pushgateway:v1.10.0                                        
```

You can continously monitor the deployment by running the following command:

```sh
# The `watch` command will continously monitor the services in the stack and update the output every 2 seconds.
watch -n1 docker stack ps promstack
```

---


## Grafana

The Grafana service is configured with config provider and config reload services. The config provider service is responsible for providing the configuration files for the Grafana service. The config reloader service is responsible for reloading the Grafana service configuration when the config provider service updates the configuration files.

The following configuration are supported:
- Grafana Dashboards
- Provisioning (Datasources, Dashboards)

#### Injecting Grafana Dashboards

To inject a Grafana Provisioning configurations, you need to specify config object in your `docker-compose.yml` or `docker-stack.yml` file as shown below. The label `io.grafana.dashboard=true` is used by the config provider service to inject the dashboards into Grafana.

```yaml
# See grafana/docker-stack.yml
configs:
  # Grafana & Prometheus dashboards
  gf-dashboard-grafana-metrics:
    name: gf-dashboard-grafana-metrics-v1
    file: ./dashboards/grafana-metrics.json
    labels:
      io.grafana.dashboard: "true"
```

#### Injecting Grafana Provisioning configurations

To inject a Grafana Provisioning configurations, you need to specify config object in your `docker-compose.yml` or `docker-stack.yml` file as shown below.

There are two types of provisioning configurations:
- Dashboards: Use `io.grafana.provisioning.dashboard=true` label to inject the provisioning configuration for dashboards.
- Datasources: Use `io.grafana.provisioning.datasource=true` label to inject the provisioning configuration for data sources.

```yaml
# See grafana/docker-stack.yml
configs:
  # Grafana dashboards provisioning config
  gf-provisioning-dashboards:
    name: gf-provisioning-dashboards-v1
    file: ./provisioning/dashboards/grafana-dashboards.yml
    labels:
      io.grafana.provisioning.dashboard: "true"

  # Grafana datasources provisioning config
  gf-provisioning-datasource-prometheus:
    name: gf-provisioning-datasource-prometheus-v1
    file: ./provisioning/datasources/prometheus.yaml
    labels:
      io.grafana.provisioning.datasource: "true"
```

## Prometheus

By design, the Prometheus server is configured to automatically discover and scrape the metrics from the Docker Swarm nodes, services and tasks. The default data retention is 182 days or ~6 months.

You can use Docker object labels in the `deploy` block to automagically register services as targets for Prometheus. It also configured with config provider and config reloader services.

#### Register services as Prometheus targets

- `io.prometheus.enabled`: Enable the Prometheus scraping for the service.
- `io.prometheus.job_name`: The Prometheus job name. Default is `<docker_stack_namespace>/<service_name|job_name>`.
- `io.prometheus.scrape_scheme`: The scheme to scrape the metrics. Default is `http`.
- `io.prometheus.scrape_port`: The port to scrape the metrics. Default is `80`.
- `io.prometheus.metrics_path`: The path to scrape the metrics. Default is `/metrics`.
- `io.prometheus.param_<name>`: The Prometheus scrape parameters.

**Example:**

```yaml
# Annotations:
services:
  my-app:
    # ...
    networks:
      prometheus:
    deploy:
      # ...
      labels:
        io.prometheus.enabled: "true"
        io.prometheus.job_name: "my-app"
        io.prometheus.scrape_port: "8080"

# As limitations of the Docker Swarm, you need to attach the service to the prometheus network.
# This is required to allow the Prometheus server to scrape the metrics.
networks:
  prometheus:
    name: prometheus
    external: true
```

#### Register a custom scrape config

To register a custom scrape config, you need to specify config object in your `docker-compose.yml` or `docker-stack.yml` file as shown below. The label `io.prometheus.scrape_config=true` is used by the Prometheus config provider service to inject the scrape config into Prometheus.

```yaml
# See cadvisor/docker-stack.yml
configs:
  prometheus-cadvisor:
    name: prometheus-cadvisor-v1
    file: ./prometheus/cadvisor.yml
    labels:
      io.prometheus.scrape_config: "true"
```

### Configure Prometheus

You can apply custom configurations to Prometheus via Environment variables by running `docker service update` command on `promstack_prometheus` service:

```sh
# Register the Alertmanager service address
docker service update --env-add PROMETHEUS_SCRAPE_INTERVAL=15s promstack_prometheus

# Remove the Alertmanager service address
docker service update --env-rm PROMETHEUS_SCRAPE_INTERVAL promstack_prometheus
```
#### Environment variables

- `PROMETHEUS_SCRAPE_INTERVAL`: The scrape interval for Prometheus, default is `10s`
- `PROMETHEUS_SCRAPE_TIMEOUT`: The scrape timeout for Prometheus, default is `5`
- `PROMETHEUS_EVALUATION_INTERVAL`: The evaluation interval for Prometheus, default is `1m`
- `PROMETHEUS_CLUSTER_NAME`: The cluster name for Prometheus, default is `promstack`
- `PROMETHEUS_CLUSTER_REPLICA`: The cluster replica for Prometheus, default is `1`
- `PROMETHEUS_ALERTMANAGER_ADDR`: The Alertmanager service address
- `PROMETHEUS_ALERTMANAGER_PORT`: The Alertmanager service port, default is `9093`

## Services and Ports

The following services and ports are exposed by the stack:

| Service           | Port   | Cluster DNS                           |
| ----------------- | ------ | ------------------------------------- |
| Grafana           | `3000` | `grafana.svc.cluster.local`           |
| Prometheus        | `9090` | `prometheus.svc.cluster.local`        |
| Pushgateway       | `9091` | `pushgateway.svc.cluster.local`       |
| Blackbox exporter | `9115` | `blackbox-exporter.svc.cluster.local` |

The following services and ports are exposed per node:

| Service          | Port    | Mode   |
| ---------------- | ------- | ------ |
| Prometheus Agent | `19090` | `host` |
| cAdvisor         | `18080` | `host` |
| Node exporter    | `19100` | `host` |

## Troubleshooting

### Grafana dashboards are not present

If the Grafana dashboards are not present, please restart `grafana` service to reload the dashboards.

```sh
# By force updating the service, it will restart the service and reload the dashboards.
docker service update --force promstack_grafana
```

### Promethues targets are not present
Please ensure the services are attached to the `prometheus` network. This is required to allow the Prometheus server to scrape the metrics.

```yaml
# Annotations:
services:
  my-app:
    # ...
    networks:
      prometheus:
    deploy:
      # ...
      labels:
        io.prometheus.enabled: "true"
        io.prometheus.job_name: "my-app"
        io.prometheus.scrape_port: "8080"

# As limitations of the Docker Swarm, you need to attach the service to the prometheus network.
# This is required to allow the Prometheus server to scrape the metrics.
networks:
  prometheus:
    name: prometheus
    external: true
```

## License

Licensed under the MIT License. See [LICENSE](LICENSE) for more information.
