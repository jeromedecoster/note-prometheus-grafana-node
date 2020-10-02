.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z_-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-25s\033[0m%s\n", $$1, $$2 }'

setup: # install stress + docker pull prometheus + node-exporter + alertmanager + grafana ...
	./make.sh setup

dev: # local development (by calling npm script directly)
	./make.sh dev

local-prometheus: # run local prometheus
	./make.sh local-prometheus

local-node-exporter: # run local node-exporter
	./make.sh local-node-exporter

local-alertmanager: # run local alertmanager
	./make.sh local-alertmanager

local-grafana: # run local grafana
	./make.sh local-grafana

local-grafana-configure: # configure local grafana
	./make.sh local-grafana-configure

rm: # remove all running containers
	./make.sh rm

compose-up: # docker-compose up
	./make.sh compose-up
