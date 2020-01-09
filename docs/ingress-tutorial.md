# Tutorial

TCP tunnel for your IngressController Kubernetes cluster with port 80 HTTP and 443 TLS.

Scenario: you have an IngressController running on a local Kubernetes cluster, maybe it's using kubeadm and bare metal. Maybe it's an RPi cluster, or KinD on your laptop. Your IngressController such as Nginx w/ cert-manager, Caddy or Traefik cannot get or serve TLS certificates because you have no public IP.

The Inlets Pro server will give you a public IP and tunnel traffic on ports 80 and 443 to your IngressController.

## Set up Kubernetes on your laptop

You may have a preferred setup or approach or local Kubernetes, but I would recommend trying k3d, which runs k3s in a Docker container, setup is < 1m.

```sh
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash
```

Set the context for your Kubernetes cluster:

```sh
k3d create
export KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')"
```

## Install tiller

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

## Add an IngressController into your cluster

Within your Kubernetes cluster, make sure you have Nginx or a similar IngressController installed.

Install with helm for instance:

```sh
helm install stable/nginx-ingress --name nginxingress \
    --set rbac.create=true,controller.hostNetwork=false \
    --set controller.daemonset.useHostPort=false,dnsPolicy=ClusterFirstWithHostNet,controller.kind=DaemonSet
```

This creates a deployment called `nginxingress-nginx-ingress-controller` in the `default` namespace, we'll be proxying into this with inlets-pro from our exit node.

## Setup a server exit-node

Any VM is suitable, even a 5 USD DigitalOcean VM

Download the `inlets-pro` binary on your VM.

```sh
curl -SLsf https://github.com/inlets/inlets-pro-pkg/releases/download/0.4.3/inlets-pro > inlets-pro
chmod +x ./inlets-pro
```

Now run `tmux`, so that the binary stays running when you disconnect.

Now we will be proxying `nginxingress-nginx-ingress-controller` from within our Kubernetes cluster, so configure as follows:

```sh
sudo ./inlets-pro server \
    --auto-tls \
    --common-name EXIT_NODE_IP \
    --remote-tcp nginxingress-nginx-ingress-controller \
    --token $AUTHTOKEN
```

Make sure you update the `--remote-tcp`, `--token`, and `--common-name` arguments.

An auth token can be generated with: `export AUTHTOKEN=$(head -c 32 /dev/urandom | shasum -a 512)` for instance.

The server process runs as `root` so that it can open any privileged ports the client may request, these are normally `80` and `443` for an IngressController.

## Setup the client `Deployment`

Get the client `Deployment` manifest and edit it:

```sh
curl -SLs https://raw.githubusercontent.com/inlets/inlets-pro-pkg/master/artifacts/client.yaml > client.yaml
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

## Test the connectivity

You should now be able to access port 80 and 443 on your exit-node's IP.

The logs will show up in the Nginx pod found with `kubectl get pod -A`

If you visit the IP address of the public IP on port 80 or 443, you should see the normal 404 page. Next you need to create a DNS entry mapping to this IP and create a Kubernetes `Ingress` resource.

## Use-cases for the tunnel

You now have an Nginx IngressController running inside your cluster with inlets-pro tunnelling both of its ports: 80 & 443 to the VM's public IP.

* Deploy your favourite application and create an "Ingress" manifest for it

* Simple [Ingress example from Nginx](https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/complete-example)

* Deploy [OpenFaaS with SSL](https://docs.openfaas.com/reference/ssl/kubernetes-with-cert-manager/)

* Deploy a [Set Up a Private Docker Registry With TLS on Kubernetes](https://www.civo.com/learn/set-up-a-private-docker-registry-with-tls-on-kubernetes)

* Get a TLS certificate

    Rather than doing edge termination on the exit-node, we can terminate TLS within the cluster.

    Just install cert-manager using helm, setup an Ingress definition and an Issuer.

    You'll see LetsEncrypt issue you a TLS certificate which will be served from within your cluster for any clients that connect.
