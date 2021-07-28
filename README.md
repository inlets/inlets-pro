# inlets PRO - Secure HTTP and TCP tunnels that just work

<img src="docs/images/inlets-pro-sm.png" width="150px">

# Overview

inlets PRO replaces SSH tunnels, VPNs, SaaS tunnels, port-forwarding and dedicated connections.

Sound like it could be useful? Show your support with a [GitHub Star](https://github.com/inlets/inlets-pro/stargazers) ⭐️

It's compatible with any HTTP (L7) or TCP (L4) software and can work through the most challenging network conditions like captive portals, HTTP proxies, firewalls and NAT to give you access to services.

You can run the tunnel as a process, container or Kubernetes Pod, and it's easy to configure or automate it.

![Example diagram](https://raw.githubusercontent.com/inlets/inlets-pro/master/docs/images/inlets-pro-split-plane.png)
> Example of inlets PRO with a TCP tunnel for hybrid cloud. Kubernetes is optional

It's up to you whether you want to use inlets PRO as a way of exposing private traffic to the Internet, or whether you just want to make it available privately to your organisation on another network [for hybrid cloud](https://inlets.dev/blog/2021/04/07/simple-hybrid-cloud.html).

## Use-cases

You can learn specific use-cases and problems that inlets PRO can solve for Kubernetes below, or check out how it can be used as a Software Defined Network or VPN replacement [in the docs](https://docs.inlets.dev/)

* [Get Kubernetes LoadBalancers for customer demos or local development](https://inlets.dev/blog/2021/07/08/short-lived-clusters.html)
* [The Simple Way To Connect Existing Apps to Public Cloud](https://inlets.dev/blog/2021/04/07/simple-hybrid-cloud.html)
* [Reliable local port-forwarding from Kubernetes](https://inlets.dev/blog/2021/04/13/local-port-forwarding-kubernetes.html)
* [How we scaled inlets to thousands of tunnels with Kubernetes](https://inlets.dev/blog/2021/03/15/scaling-inlets.html)
* [Learn how to manage apps across multiple Kubernetes clusters](https://inlets.dev/blog/2021/06/02/argocd-private-clusters.html)

## Features

inlets-pro forwards TCP or HTTP / REST traffic over an encrypted websocket secured with TLS.

![Quick overview](https://inlets.dev/images/quick.png)

> A quick overview showing a HTTP tunnel to expose a private Node.js service on a private network.

Whichever type of service is used, inlets-pro supports load-balancing of connections and multiple clients connected to the same server. When automatic TLS is used (default) then all data is encrypted through a TLS connection.

For TCP services:

* Tunnel any L4/TCP protocols - such as databases, remote desktop, gRPC, HTTP/2 and SSH
* Legacy protocols which do not support TLS are automatically "upgraded" through the encrypted tunnel
* Pass-through TLS support for reverse proxies, Kubernetes, IngressControllers and TLS
* Multiple TCP ports are supported and can be updated by the client

For HTTPS/REST services:

* Reverse proxy with support for multiple upstreams through using the `Host` header
* Automatic Let's Encrypt for exposed using HTTP01 challenge
* Support for websockets

Deployment options:

* A single static binary is available for MacOS, Windows, and Linux. Arm is also supported
* Sample `systemd` unit files for automatic restarts and logging from `journalctl`
* Official container image available on public registry
* Kubernetes integration via `inlets-operator`, YAML or Helm

## License & Pricing

inlets-pro is a L4 and L7 TCP tunnel, service proxy, and load-balancer product distributed under a commercial license.

In order to use inlets-pro, you must accept the [End User License Agreement - EULA](EULA.md). The server component runs without a license key, but the client requires a valid license.

You can purchase a license for personal or business use on the [inlets website](https://inlets.dev/)

* [Purchase or start a free 14-day trial](https://inlets.dev)

## Reference architecture

inlets-pro can be used to provide a Public VirtualIP to private, edge and on-premises services and Kubernetes clusters. Once you have set up one or more VMs or cloud hosts on public cloud, you can utilize their IP addresses with inlets-pro.

You can get incoming networking (ingress) to any:

* gRPC services with or without TLS
* Access unsecured private services like MySQL, but with TLS link-encryption
* Command & control of Point of Sale / IoT devices
* SSH access to home-lab or Raspberry Pi
* TCP services running on Linux, Windows or MacOS
* The API of your Kubernetes cluster
* A VM or Docker container

For example, rather than terminating TLS at the edge of the tunnel, inlets-pro can forward the TLS traffic on port `443` directly to your host, where you can run a reverse proxy inside your network. At any time you can disconnect and reconnect the tunnel or even delete the remote VM without loosing your TLS certificate since it's stored locally.

See also: [reference architecture diagrams](/docs/reference.md)

## Get started

You can follow one of the tutorials above, or use inlets PRO in three different ways:

* As a stand-alone binary which you can manage manually or automate
* Through [inletsctl](https://github.com/inlets/inletsctl) which creates an exit server with `inlets-pro server` running with systemd in one of the cloud / IaaS platforms such as AWS EC2 or DigitalOcean
* Through [inlets-operator](https://github.com/inlets/inlets-operator) - the operator runs on Kubernetes and creates an exit server running `inlets-pro server` and a Pod in your cluster running `inlets-pro client`. The lifecycle of the client and server and exit-node are all automated.

### Tutorials and examples

* [News and use-cases on the blog](https://inlets.dev/blog)
* [Reference documentation](https://docs.inlets.dev)
* [inlets PRO CLI reference guide](docs/cli-reference.md)

### Get the binary

Both the client and server are contained within the same binary.

It is recommended that you use [inletsctl](https://github.com/inlets/inletsctl), or [inlets-operator](https://github.com/inlets/inlets-operator) to create inlets-pro exit serves, but you can also work directly with its binary or Docker image.

The inlets-pro binary can be obtained as a stand-alone executable, or via a Docker image.

* As a binary:

    ```sh
    curl -SLsf https://github.com/inlets/inlets-pro/releases/download/0.8.6/inlets-pro > inlets-pro
    chmod +x ./inlets-pro
    ```

    Or fetch via `inletsctl download --pro`

    Or find a binary for [a different architecture on the releases page](https://github.com/inlets/inlets-pro/releases)

    See also [CLI reference guide](docs/cli-reference.md)

* Docker image

    A docker image is published at `ghcr.io/inlets/inlets-pro:0.8.6`
    
    See the image on [GitHub Container Registry](https://github.com/orgs/inlets/packages/container/package/inlets-pro)

### Kubernetes

* Automatic tunnel servers and clients through LoadBalancer/Ingress

    See also: [inlets-operator](https://github.com/inlets/inlets-operator)

* Kubernetes Helm charts

    Run ad-hoc clients and servers on your Kubernetes clusters

    See [chart](chart) for the inlets-pro TCP client and server mode

    A separate helm chart is available to inlets-pro customers for the HTTP client and server mode

* Pre-provisioned inlets tunnel servers

    [Read how here](https://inlets.dev/blog/2021/07/08/short-lived-clusters.html)

* Sample Kubernetes YAML files

    A [client](artifacts/client.yaml) and [server](artifacts/server.yaml) YAML file are also available as samples

## Get in touch

Got questions? Send us an email to [contact@openfaas.com](mailto:contact@openfaas.com).
