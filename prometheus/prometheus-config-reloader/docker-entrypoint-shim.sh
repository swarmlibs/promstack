#!/usr/bin/env sh
# Copyright (c) Swarm Library Maintainers.
# SPDX-License-Identifier: MIT
set -xe
exec prometheus-config-reloader \
    --listen-address=:8080 \
    --config-file=${RELOADER_CONFIG_FILE} \
    --watch-interval=${RELOADER_WATCH_INTERVAL} \
    --watched-dir=${RELOADER_WATCH_DIR} \
    --reload-timeout=${RELOADER_RELOAD_TIMEOUT} \
    --reload-url=http://${PROMETHEUS_HOST}:9090/-/reload \
    --runtimeinfo-url=http://${PROMETHEUS_HOST}:9090/api/v1/status/runtimeinfo
