# inlets-pro

inlets-pro is an L4 TCP load-balancer.

## Features

inlets-pro forwards TCP traffic over an encrypted websocket secured with TLS.

* Support for any TCP protocol
* Automatic TLS encryption for tunnel and control-port
* Pass-through L4 proxy
* Automatic port detection, as announced by client
* `systemd` support and automatic retries
* Kubernetes compatible

## Use-case
 
It is well suited to forward traffic from a VM on the Internet to a private or development Kubernetes cluster.

You can get incoming networking (ingress) to any:

* machine running Linux, Windows or MacOS
* Kubernetes cluster
* VM or Docker container

For example, rather than terminating TLS at the edge of the tunnel, inlets-pro can forward the TLS traffic on port `443` directly to your host, where you can run a reverse proxy inside your network. At any time you can disconnect and reconnect the tunnel or even delete the remote VM without loosing your TLS certificate since it's stored locally.

* What can I run? Give me a use-case.

    You could run a Docker registry complete with TLS served completely within your local network. This guide could be followed on a KinD, Minikube or bare-metal cluster behind a firewall and still work the same because the tunnel provides TCP ingress.
    
    Once the tunnel is established with the instructions in this repo, you could run the following tutorial on your laptop or local network.

## Tutorials

In this example we will forward ports 80 and 443 from the exit-node to the IngressController running within the cluster. We could forward anything that can be transported over TCP i.e. TLS, MongoDB, SSH, Redis, or whatever you want.

* [TCP tunnel for your IngressController Kubernetes cluster with port 80 HTTP and 443 TLS](docs/ingress-tutorial.md)
* [TCP tunnel for Apache Cassandra running on your local machine, out to another network](docs/cassandra-tutorial.md)
* [TCP tunnel for Caddy - get a TLS cert directly for your local machine](docs/caddy-tutorial.md)

## Getting the binaries

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

inlets-pro is a L4 TCP tunnel and load-balancer distributed under a commercial license.

### Getting a license key / more info

* See the [EULA](EULA.md)

* [Start a 14-day trial today](https://docs.google.com/forms/d/e/1FAIpQLScfNQr1o_Ctu_6vbMoTJ0xwZKZ3Hszu9C-8GJGWw1Fnebzz-g/viewform?usp=sf_link)

Contact [Alex Ellis](mailto:alex@openfaas.com) for more information.
