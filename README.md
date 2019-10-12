# inlets-pro-pkg

Inlets Pro

## What is this?

Inlets Pro is an L4 TCP load-balancer which can be used to forward TCP traffic over a websocket.

It is well suited to forward traffic from a VM on the Internet to a private or development Kubernetes cluster.

You can get incoming networking (ingress) to any:

* machine running Linux, Windows or MacOS
* Kubernetes cluster
* VM or Docker container

For example, rather than terminating TLS at the edge of the tunnel, inlets-pro can forward the TLS traffic on port `443` directly to your host, where you can run a reverse proxy inside your network. At any time you can disconnect and reconnect the tunnel or even delete the remote VM without loosing your TLS certificate since it's stored locally.

## Installation

In this example we will forward ports 80 and 443 from the exit-node to the IngressController running within the cluster. We could forward anything that can be transported over TCP i.e. TLS, MongoDB, SSH, Redis, or whatever you want.

* Setup a server exit-node

    Any VM is suitable, even a 5 USD DigitalOcean VM

    Download the `inlets-pro` binary on your VM.

    Now we will be proxying `nginxingress-nginx-ingress-controller` from within our Kubernetes cluster, so configure as follows:

    ```sh
    ./inlets-pro-linux server \
        --auto-tls \
        --common-name EXIT_NODE_IP \
        --remote-tcp nginxingress-nginx-ingress-controller
    ```

* Setup the client Pod

    Within your Kubernetes cluster, make sure you have Nginx or a similar IngressController installed.

    Install with helm for instance:

    ```sh
    helm install stable/nginx-ingress --name nginxingress --set rbac.create=true,controller.hostNetwork=false controller.daemonset.useHostPort=false,dnsPolicy=ClusterFirstWithHostNet,controller.kind=DaemonSet
    ```

    Update `artifacts/client.yaml`

    ```yaml
        - "--connect=wss://EXIT_NODE_IP:8123/connect"
        - "--tcp-ports=80,443"
        - "--id=foo"
        - "--license=LICENSE_JWT_HERE"
    ```

    Edit `--license` with your license for Inlets Pro
    Edit `--connect` with the IP of your exit node

* Get a TLS certificate

    Rather than doing edge termination on the exit-node, we can terminate TLS within the cluster.

    Just install cert-manager using helm, setup an Ingress definition and an Issuer.

    You'll see LetsEncrypt issue you a TLS certificate which will be served from within your cluster for any clients that connect.

## Getting the binaries

Both the client and server are contained within the same binary.

* The client
    
    The client.yaml file for Kubernetes runs the client and requires a license key, the server component does not.

* The server (exit-node)

    ```sh
    curl -SLsf https://github.com/alexellis/inlets-pro-pkg/releases/download/0.1.0/inlets-pro-linux > inlets-pro-linux
    chmod +x ./inlets-pro-linux
    ```

## Getting a license

Contact Alex Ellis for a key.
