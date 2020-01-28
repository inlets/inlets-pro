# inlets-pro

Inlets Pro is an L4 TCP Tunnel and Service Proxy

You can use it to tunnel out any TCP traffic from an internal network to another network. This could be green-to-green, or green-to-red, i.e. from internal/private to the Internet. It differs from [Inlets OSS](https://inlets.dev/) in that it works at the L4 layer, with TCP and has automatic TLS built-in.

## Features

inlets-pro forwards TCP traffic over an encrypted websocket secured with TLS.

* Support for any TCP protocol
* Pass-through L4 proxy
* Automatic TLS encryption for tunnel and control-port
* Automatic port-detection, announced by client

Deployment options:

* single static binary is available for MacOS, Windows, and Linux on armhf and ARM64
* `systemd` support with automatic restarts
* Native `docker` image available
* Kubernetes integration via `inlets-operator` or YAML

## Use-case
 
It is well suited to forward traffic from a VM on the Internet to a private or development Kubernetes cluster.

You can get incoming networking (ingress) to any:

* Command & control of Point of Sale / IoT devices
* SSH access to home-lab or Raspberry Pi
* TCP services running on Linux, Windows or MacOS
* The API of your Kubernetes cluster
* A VM or Docker container

For example, rather than terminating TLS at the edge of the tunnel, inlets-pro can forward the TLS traffic on port `443` directly to your host, where you can run a reverse proxy inside your network. At any time you can disconnect and reconnect the tunnel or even delete the remote VM without loosing your TLS certificate since it's stored locally.

* What can I run? Give me a use-case.

    You could run a Docker registry complete with TLS served completely within your local network. This guide could be followed on a KinD, Minikube or bare-metal cluster behind a firewall and still work the same because the tunnel provides TCP ingress.
    
    Once the tunnel is established with the instructions in this repo, you could run the following tutorial on your laptop or local network.

## Get started

You can follow one of the tutorials above, or use inlets-pro in one of three ways:

* On its own as a stand-alone binary, which you can manage manually, or automate
* Through `inletsctl` which creates an exit server with `inlets-pro server` running with systemd in one of the cloud / IaaS platforms such as AWS EC2 or DigitalOcean
* Through `inlets-operator` - the operator runs on Kubernetes and creates an exit server running `inlets-pro server` and a Pod in your cluster running `inlets-pro client`. The lifecycle of the client and server and exit-node are all automated.

### Tutorials and examples

In this example we will forward ports 80 and 443 from the exit-node to the IngressController running within the cluster. We could forward anything that can be transported over TCP i.e. TLS, MongoDB, SSH, Redis, or whatever you want.

* [Tunnel your IngressController Kubernetes cluster with port 80 HTTP and 443 TLS](docs/ingress-tutorial.md)
* [Tunnel Apache Cassandra running on your local machine, out to another network](docs/cassandra-tutorial.md)
* [Tunnel Caddy - get a TLS cert directly for your local machine](docs/caddy-tutorial.md)

* [Expose your local Kubernetes API server to the Internet](https://gist.github.com/alexellis/368798641182f92721eab9007045cf89)

### Get the binary

Both the client and server are contained within the same binary.

* The client
    
    The client.yaml file for Kubernetes runs the client and requires a license key, the server component does not.

* The server (exit-node)

    ```sh
    curl -SLsf https://github.com/inlets/inlets-pro-pkg/releases/download/0.4.3/inlets-pro > inlets-pro
    chmod +x ./inlets-pro
    ```

## License

[inlets](https://inlets.dev) is a free, L7 HTTP tunnel and OSS software under the MIT license.

inlets-pro is a L4 TCP tunnel, service proxy, and load-balancer distributed under a commercial license.

### Getting a license key

1) Accept the [End User License Agreement - EULA](EULA.md)
2) [Start a 14-day trial today](https://docs.google.com/forms/d/e/1FAIpQLScfNQr1o_Ctu_6vbMoTJ0xwZKZ3Hszu9C-8GJGWw1Fnebzz-g/viewform?usp=sf_link)
2) Receive your license via email from OpenFaaS Ltd
3) Use community support if required via [OpenFaaS Slack](https://slack.openfaas.io/) in the #inlets channel

**After completing your trial**, please contact [sales@openfaas.com](mailto:sales@openfaas.com) for to purchase a commercial-license.
