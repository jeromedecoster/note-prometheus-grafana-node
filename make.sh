#!/bin/bash

# the directory containing the script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"

log()   { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }        # $1 uppercase background white
info()  { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }      # $1 uppercase background green
warn()  { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red

# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

# docker pull prometheus + node-exporter + alertmanager + grafana ...
setup() {
    # docker pull ...
    log docker pull prom/prometheus
    docker pull prom/prometheus

    log docker pull prom/node-exporter
    docker pull prom/node-exporter

    log docker pull prom/alertmanager
    docker pull prom/alertmanager

    log docker pull grafana/grafana
    docker pull grafana/grafana

    log docker pull node:14.9-slim
    docker pull node:14.9-slim

    log docker pull alpine:3.10
    docker pull alpine:3.10
}

# local development (by calling npm script directly)
dev() {
    cd "$dir/site/src"
    npm run-script dev

    log site http://localhost:5000
    log metrics http://localhost:5000/metrics
}

# run local prometheus
local-prometheus() {
    cd "$dir"

    # rm previously runned container
    docker rm --force prometheus 2>/dev/null

    docker run --detach \
        --name=prometheus \
        --network host \
        --volume $(pwd)/local-prometheus.yaml:/etc/prometheus/prometheus.yaml \
        --volume $(pwd)/local-rules.yaml:/etc/prometheus/rules.yaml \
        prom/prometheus \
        --config.file=/etc/prometheus/prometheus.yaml

    log alerts http://localhost:9090/alerts
    log rules http://localhost:9090/rules

    # request_count : http://localhost:9090/graph?g0.range_input=1h&g0.expr=request_count&g0.tab=1
    # queue_size : http://localhost:9090/graph?g0.range_input=1h&g0.expr=queue_size&g0.tab=1
    # request_duration_bucket : http://localhost:9090/graph?g0.range_input=1h&g0.expr=request_duration_bucket&g0.tab=1
    # request_duration_sum : http://localhost:9090/graph?g0.range_input=1h&g0.expr=request_duration_sum&g0.tab=1
}

# run local node-exporter
local-node-exporter() {
    # rm previously runned container
    docker rm --force node-exporter 2>/dev/null

    docker run --detach \
        --name node-exporter \
        --restart=always \
        --network host \
        prom/node-exporter

    log metrics http://localhost:9100/metrics
}

# run local alertmanager
local-alertmanager() {
    # rm previously runned container
    docker rm --force alertmanager 2>/dev/null

    docker run --detach \
        --name=alertmanager \
        --network host \
        --volume $(pwd)/local-alert.yaml:/etc/alertmanager/local-alert.yaml \
        prom/alertmanager \
        --config.file=/etc/alertmanager/local-alert.yaml

    log alerts http://localhost:9093
}

# run local grafana
local-grafana() {
    cd "$dir"

    # rm previously runned container
    docker rm --force grafana 2>/dev/null

    docker run --detach \
        --env GF_AUTH_BASIC_ENABLED=false \
        --env GF_AUTH_ANONYMOUS_ENABLED=true \
        --env GF_AUTH_ANONYMOUS_ORG_ROLE=Admin \
        --name=grafana \
        --network host \
        grafana/grafana

    log grafana http://localhost:3000
}

# configure local grafana
local-grafana-configure() {
    cd "$dir"

    log add datasource
    curl http://localhost:3000/api/datasources \
        --header 'Content-Type: application/json' \
        --data @local-datasource.json

    log create dashboard-1860.json
    curl https://grafana.com/api/dashboards/1860 | jq '.json' > dashboard-1860.json

    # wrap some JSON data
    log create dashboard-1860-modified.json
    ( echo '{ "overwrite": true, "dashboard" :'; \
    cat dashboard-1860.json; \
    echo '}' ) \
    | jq \
    > dashboard-1860-modified.json

    log add dashboard-1860
    curl http://localhost:3000/api/dashboards/db \
        --header 'Content-Type: application/json' \
        --data @dashboard-1860-modified.json

    log add my-dashboard
    curl http://localhost:3000/api/dashboards/db \
        --header 'Content-Type: application/json' \
        --data @local-my-dashboard.json

    # http://localhost:3000/d/cT-ufiKGz/my-dashboard?orgId=1&refresh=1m&from=now-5m&to=now
    # http://localhost:3000/d/rYdddlPWk/node-exporter-full?orgId=1&refresh=1m&from=now-5m&to=now
}

# remove all running containers
rm() {
    docker rm --force prometheus 2>/dev/null
    docker rm --force node-exporter 2>/dev/null
    docker rm --force alertmanager 2>/dev/null
    docker rm --force grafana 2>/dev/null
}

# docker-compose up
compose-up() {
    cd "$dir"

    docker-compose \
        --project-name compose_prometheus_grafana \
        up \
        --build
}


# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0