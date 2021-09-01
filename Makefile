.PHONY: charts all

all: charts

charts:
	cd chart
	helm package inlets-http-server
	helm package inlets-pro
	helm package inlets-pro-client
	cd ..
	mv chart/*.tgz docs/
	helm repo index docs --url https://inlets.github.io/inlets-pro/ --merge ./docs/index.yaml
