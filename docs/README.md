# inlets-pro docs

Learn more on the [official documentation site](https://docs.inlets.dev/)

Read use-cases and tutorials [on the blog](https://blog.inlets.dev)

For the helm charts:

```bash
$ helm repo add inlets-pro https://inlets.github.io/inlets-pro/charts/
$ helm repo update

$ helm search repo inlets-pro
NAME                            CHART VERSION   APP VERSION     DESCRIPTION                            
inlets-pro/inlets-tcp-server           0.2.1           1.16.0          Helm chart for an inlets-pro TCP server
inlets-pro/inlets-tcp-client    0.2.1           1.0.0           Helm chart for an inlets-pro TCP client
inlets-pro/inlets-http-server   0.2.1           1.16.0          Helm chart for an inlets HTTP server  
```

Then install with the instructions at: [inlets/inlets-pro/tree/master/chart](https://github.com/inlets/inlets-pro/tree/master/chart)
