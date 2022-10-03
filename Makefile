.PHONY: charts all

all: charts

charts:
	cd chart && \
	helm package inlets-http-server/ && \
	helm package inlets-tcp-server/ && \
	helm package inlets-tcp-client/
	mv chart/*.tgz docs/charts
	helm repo index docs/charts --url https://inlets.github.io/inlets-pro/charts --merge ./docs/charts/index.yaml
