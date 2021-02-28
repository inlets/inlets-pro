## Helm charts for inlets PRO

[inlets PRO](https://inlets.dev/) consists of a client and a server portion.

When a client wants to expose a service publicly, or privately within a remote network, it connects to a server using its control-plane (a HTTPS websocket).

There is no need for your data plane to be exposed on the Internet, you can bind to a local LAN adapter, or a private ClusterIP. If you do want to expose your tunnelled services to the Internet, you can do with a NodePort, LoadBalancer or through Ingress.

### Deploy an inlets PRO server

* [Use your Kubernetes cluster for exit-servers](https://github.com/inlets/inlets-pro/tree/master/chart/inlets-pro)

### Deploy an inlets PRO client

* [Run an inlets PRO client in your Kubernetes cluster](https://github.com/inlets/inlets-pro/tree/master/chart/inlets-pro-client)

### Automate Service LoadBalancers for your cluster

See also: [inlets-operator](https://github.com/inlets/inlets-operator) which automates both parts of the above for a set number of supported clouds, and integrates through Kubernetes services of type LoadBalancer.
