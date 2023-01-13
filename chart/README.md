## Helm charts for inlets

[inlets](https://inlets.dev) has both a client and a server, which connect to each other to build a tunnel.

When a client wants to expose a service publicly, or privately within a remote network, it connects to a server using its control-plane (a HTTPS websocket).

There is no need for your data plane to be exposed on the Internet, you can bind to a local LAN adapter, or a private ClusterIP. If you do want to expose your tunnelled services to the Internet, you can do with a NodePort, LoadBalancer or through Ingress.

Kubernetes v1.19+ is required for the helm charts provided in this repository, due to the various versions of the Ingress API, the minimum supported version will be `networking.k8s.io/v1`.

### Deploy the inlets tunnel client or server as a Kubernetes Deployment

* [Deploy an inlets HTTP server](inlets-http-server)

* [Deploy an inlets TCP client](inlets-tcp-client)

* [Deploy an inlets TCP server](inlets-tcp-server)

## Other Kubernetes use-cases

### Get Public L4 Load Balancers for your cluster

See also: [inlets-operator](https://github.com/inlets/inlets-operator) which automates both parts of the above for a set number of supported clouds, and integrates through Kubernetes services of type LoadBalancer.

### Setup your preferred IngressController with TLS certs from Let's Encrypt

* [Quick-start: Expose Your IngressController and get TLS from LetsEncrypt and cert-manager](https://docs.inlets.dev/#/get-started/quickstart-ingresscontroller-cert-manager?id=quick-start-expose-your-ingresscontroller-and-get-tls-from-letsencrypt-and-cert-manager)

### Get kubectl access to your private cluster from anywhere

* [Tutorial: Expose a local Kubernetes API Server](https://docs.inlets.dev/tutorial/kubernetes-api-server/)

### Continous Deployment and fleet management with ArgoCD

* [How To Manage Inlets Tunnels Servers With Argo CD and GitOps](https://inlets.dev/blog/2022/08/10/managing-tunnel-servers-with-argocd.html)
* [Argo CD for your private Raspberry Pi k3s cluster](https://johansiebens.dev/posts/2020/08/argo-cd-for-your-private-raspberry-pi-k3s-cluster/)
