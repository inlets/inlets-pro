.PHONY: charts all

all: charts

charts:
	cd chart && \
	helm package inlets-http-server/ && \
	helm package inlets-pro/ && \
	helm package inlets-pro-client/
	mv chart/*.tgz docs/charts
	helm repo index docs/charts --url https://inlets.github.io/inlets-pro/ --merge ./docs/charts/index.yaml
