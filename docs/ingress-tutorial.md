# Tutorial

TCP tunnel for your IngressController Kubernetes cluster with port 80 HTTP and 443 TLS.

Scenario: you have an IngressController running on a local Kubernetes cluster, maybe it's using kubeadm and bare metal. Maybe it's an RPi cluster, or KinD on your laptop. Your IngressController such as Nginx w/ cert-manager, Caddy or Traefik cannot get or serve TLS certificates because you have no public IP.

The Inlets Pro server will give you a public IP and tunnel traffic on ports 80 and 443 to your IngressController.

## Get the `k3sup` utility

The `k3sup` utility makes installing the various parts of this tutorial much easier, than when following manual steps for each component.

```sh
curl -sSLf https://get.k3sup.dev | sudo sh
```

> Note: that despite the word `k3` in the name `k3sup` works with any Kubernetes cluster, including KinD, minikube and Docker Desktop.

## Set up Kubernetes on your laptop

You may have a preferred setup or approach or local Kubernetes, but I would recommend trying k3d, which runs k3s in a Docker container, setup is < 1m.

By default k3d comes with Traefik, which also works with inlets-pro, but we're going to disable it and use the more common Nginx-ingress.

```sh
# Get the k3d binary
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash

# Create the cluster
k3d create --server-arg "--no-deploy=traefik,svclb"

export KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')"
```

## Get a cloud API token

DigitalOcean is the easiest cloud to get started with, but you can also use your own infrastructure with inlets-pro.

Head over to your dashboard and create an API key, save it as `~/Downloads/do-access-token`

## Install the inlets-operator

Next we need two parts, the client and the server. The client runs inside your cluster as a Pod, and the server runs on a server with a public IP, or an IP in another network that we want to expose our IngressController on.

Install the inlets-operator which automates the creation of the client Pod and the exit server.

```sh
export LICENSE="" # Set your inlets-pro license key here

k3sup app install inlets-operator \
  --provider digitalocean \
  --region lon1 \
  --token-file ~/Downloads/do-access-token \
  --license "${LICENSE}"
```

See also `k3sup app install inlets-operator --help` for more options.

## Install Nginx IngressController

```sh
k3sup app install nginx-ingress
```

## Access your IngressController

Now look for the LoadBalancer and external IP in your cluster created by the Nginx app:

```sh
kubectl get service/nginx-ingress-controller

NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
nginx-ingress-controller   LoadBalancer   10.43.148.130   167.172.58.2  80:30077/TCP,443:32437/TCP   15s
```

You'll be able to access your IP via `curl`, or in a web-browser:

```
# We have no Ingress or TLS records yet, so the cert will show as invalid
curl -k -i http://167.172.58.2:443

# And we can access the HTTP endpoint
curl -i http://167.172.58.2:80
```

The above shows both port 80 and 443 being tunnelled to your VM and exposed via its public IP.

You can create a DNS entry and point it at this IP, and even get a TLS certificate with tooling like cert-manager.

### Wrapping up

You've now created a cluster on your private network, with a local IngressController that has a real public IP. Any traffic that hits port 80 on the IngressController will redirected to your IngressController inside your cluster.

Here's a couple of labs that you could pick up and carry on with. 

* [Get a TLS cert for your application with JetStack's cert-manager](https://github.com/alexellis/tls-with-cert-manager)

* [OpenFaaS with a HTTPS certificate with k3sup](https://blog.alexellis.io/tls-the-easy-way-with-openfaas-and-k3sup/), or deploy your own Ingress resource.

Or just deploy your favourite application and create an "Ingress" manifest for it

#### Clean up the resources (optional)

The operator will delete your exit-node automatically, if you delete the Nginx Service with `kubectl delete service/nginx-ingress-controller`.

You can then run `k3d delete` and you should be back to where you started.

