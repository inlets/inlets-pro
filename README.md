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

* What can I run? Give me a use-case.

    You could run a Docker registry complete with TLS served completely within your local network. This guide could be followed on a KinD, Minikube or bare-metal cluster behind a firewall and still work the same because the tunnel provides TCP ingress.
    
    Once the tunnel is established with the instructions in this repo, you could run the following tutorial on your laptop or local network.

    Example tutorial: [Set Up a Private Docker Registry With TLS on Kubernetes](https://www.civo.com/learn/set-up-a-private-docker-registry-with-tls-on-kubernetes)

## Installation

In this example we will forward ports 80 and 443 from the exit-node to the IngressController running within the cluster. We could forward anything that can be transported over TCP i.e. TLS, MongoDB, SSH, Redis, or whatever you want.

### Set up Kubernetes on your laptop

You may have a preferred setup or approach or local Kubernetes, but I would recommend trying k3d, which runs k3s in a Docker container, setup is < 1m.

```sh
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash
```

Set the context for your Kubernetes cluster:

```sh
k3d create
export KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')"
```

### Install tiller

Create RBAC permissions for tiller

```sh
kubectl -n kube-system create sa tiller \
&& kubectl create clusterrolebinding tiller \
--clusterrole cluster-admin \
--serviceaccount=kube-system:tiller
```

Install the server-side Tiller component on your cluster

```sh
helm init --skip-refresh --upgrade --service-account tiller
```

### Add an IngressController into your cluster

Within your Kubernetes cluster, make sure you have Nginx or a similar IngressController installed.

Install with helm for instance:

```sh
helm install stable/nginx-ingress --name nginxingress \
    --set rbac.create=true,controller.hostNetwork=false \
    --set controller.daemonset.useHostPort=false,dnsPolicy=ClusterFirstWithHostNet,controller.kind=DaemonSet
```

This creates a deployment called `nginxingress-nginx-ingress-controller` in the `default` namespace, we'll be proxying into this with inlets-pro from our exit node.

### Setup a server exit-node

Any VM is suitable, even a 5 USD DigitalOcean VM

Download the `inlets-pro` binary on your VM.

```sh
curl -SLsf https://github.com/alexellis/inlets-pro-pkg/releases/download/0.4.0/inlets-pro-linux > inlets-pro-linux
chmod +x ./inlets-pro-linux
```

Now run `tmux`, so that the binary stays running when you disconnect.

Now we will be proxying `nginxingress-nginx-ingress-controller` from within our Kubernetes cluster, so configure as follows:

```sh
sudo ./inlets-pro-linux server \
    --auto-tls \
    --common-name EXIT_NODE_IP \
    --remote-tcp nginxingress-nginx-ingress-controller
    --token $AUTHTOKEN
```

Make sure you update the `--remote-tcp`, `--token`, and `--common-name` arguments.

An auth token can be generated with: `export AUTHTOKEN=$(head -c 32 /dev/urandom | shasum -a 512)` for instance.

The server process runs as `root` so that it can open any privileged ports the client may request, these are normally `80` and `443` for an IngressController.

### Setup the client `Deployment`

Get the client `Deployment` manifest and edit it:

```sh
curl -SLs https://raw.githubusercontent.com/alexellis/inlets-pro-pkg/master/artifacts/client.yaml > client.yaml
```

Update `client.yaml`:

```yaml
    - "--connect=wss://EXIT_NODE_IP:8123/connect"
    - "--tcp-ports=80,443"
    - "--token=AUTHTOKENHERE"
    - "--license=LICENSE_JWT_HERE"
```

Edit `--license` with your license for Inlets Pro
Edit `--connect` with the IP of your exit node
Edit `--token` with the shared authentication token

Now apply the YAML file to start the tunnel from within the cluster: `kubectl apply -f artifacts/client.yaml`.

### Test the connectivity

You should now be able to access port 80 and 443 on your exit-node's IP.

The logs will show up in the Nginx pod found with `kubectl get pod -A`

If you visit the IP address of the public IP on port 80 or 443, you should see the normal 404 page. Next you need to create a DNS entry mapping to this IP and create a Kubernetes `Ingress` resource.

### Use-cases for the tunnel

You now have an Nginx IngressController running inside your cluster with inlets-pro tunnelling both of its ports: 80 & 443 to the VM's public IP.

* Deploy your favourite application and create an "Ingress" manifest for it

* Simple [Ingress example from Nginx](https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/complete-example)

* Deploy [OpenFaaS with SSL](https://docs.openfaas.com/reference/ssl/kubernetes-with-cert-manager/)

* Deploy a [Set Up a Private Docker Registry With TLS on Kubernetes](https://www.civo.com/learn/set-up-a-private-docker-registry-with-tls-on-kubernetes)

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
    curl -SLsf https://github.com/alexellis/inlets-pro-pkg/releases/download/0.4.0/inlets-pro-linux > inlets-pro-linux
    chmod +x ./inlets-pro-linux
    ```

## License

[inlets](https://inlets.dev) is a free, L7 HTTP tunnel and OSS software under the MIT license.

inlets-pro is a L4 TCP tunnel and load-balancer distributed under a commercial license.

### Getting a license key / more info

* See the [EULA](EULA.md)

* [Start a 14-day trial today](https://docs.google.com/forms/d/e/1FAIpQLScfNQr1o_Ctu_6vbMoTJ0xwZKZ3Hszu9C-8GJGWw1Fnebzz-g/viewform?usp=sf_link)

Contact [Alex Ellis](mailto:alex@openfaas.com) for more information.
