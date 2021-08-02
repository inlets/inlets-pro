## Helm charts for inlets PRO

[inlets PRO](https://inlets.dev/) consists of a client and a server portion.

When a client wants to expose a service publicly, or privately within a remote network, it connects to a server using its control-plane (a HTTPS websocket).

There is no need for your data plane to be exposed on the Internet, you can bind to a local LAN adapter, or a private ClusterIP. If you do want to expose your tunnelled services to the Internet, you can do with a NodePort, LoadBalancer or through Ingress.

### Deploy an inlets PRO TCP server

* [Use your Kubernetes cluster for exit-servers](https://github.com/inlets/inlets-pro/tree/master/chart/inlets-pro)

### Deploy an inlets PRO TCP client

* [Run an inlets PRO client in your Kubernetes cluster](https://github.com/inlets/inlets-pro/tree/master/chart/inlets-pro-client)

### Deploy an inlets PRO HTTP client or server

To deploy a client or server, request access to the helm chart after your purchase.

### Setup your preferred IngressController with TLS certs from Let's Encrypt

* [Quick-start: Expose Your IngressController and get TLS from LetsEncrypt and cert-manager](https://docs.inlets.dev/#/get-started/quickstart-ingresscontroller-cert-manager?id=quick-start-expose-your-ingresscontroller-and-get-tls-from-letsencrypt-and-cert-manager)

### Get kubectl access to your private cluster from anywhere

* [Get kubectl access to your private cluster from anywhere](https://blog.alexellis.io/get-private-kubectl-access-anywhere/)

### Continous Deployment and fleet management with ArgoCD

* [Argo CD for your private Raspberry Pi k3s cluster](https://johansiebens.dev/posts/2020/08/argo-cd-for-your-private-raspberry-pi-k3s-cluster/)

### Get Public L4 LoadBalancers for your cluster

See also: [inlets-operator](https://github.com/inlets/inlets-operator) which automates both parts of the above for a set number of supported clouds, and integrates through Kubernetes services of type LoadBalancer.
