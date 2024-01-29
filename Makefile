.PHONY: charts all

VERBOSE?=false

all: verify-charts charts

verify-charts:
	@echo Verifying helm charts images in remote registries && \
	arkade chart verify --verbose=$(VERBOSE) -f ./chart/inlets-http-server/values.yaml && \
	arkade chart verify --verbose=$(VERBOSE) -f ./chart/inlets-tcp-client/values.yaml && \
	arkade chart verify --verbose=$(VERBOSE) -f ./chart/inlets-tcp-server/values.yaml

upgrade-charts:
	@echo Upgrading images for all helm charts && \
	arkade chart upgrade --verbose=$(VERBOSE) -w -f ./chart/inlets-http-server/values.yaml && \
	arkade chart upgrade --verbose=$(VERBOSE) -w -f ./chart/inlets-tcp-client/values.yaml && \
	arkade chart upgrade --verbose=$(VERBOSE) -w -f ./chart/inlets-tcp-server/values.yaml

charts:
	cd chart && \
	helm package inlets-http-server/ && \
	helm package inlets-tcp-server/ && \
	helm package inlets-tcp-client/
	mv chart/*.tgz docs/charts
	helm repo index docs/charts --url https://inlets.github.io/inlets-pro/charts --merge ./docs/charts/index.yaml
