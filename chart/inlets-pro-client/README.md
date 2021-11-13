## Run an inlets PRO client in your Kubernetes cluster

An inlets PRO client can be used to tunnel a service from a local cluster to a remote network or remote Kubernetes cluster.

You should decide whether you want to expose the remote service to the world, or to just the local area network of the exit-server.

### Prerequisites

You will need to set up an inlets PRO TCP server so that the client has an endpoint to connect to. Create a server manually and then configure inlets-pro, or use [inletsctl](https://github.com/inlets/inletsctl) to create a preconfigured cloud VM, or use the helm chart for the inlets-pro server to install the server into a Pod.

Install [arkade](https://arkade.dev/), which is used in the tutorial to install Kubernetes software.

```bash
curl -sLS https://dl.arkade.dev | sh        # Move to /usr/local/bin/
curl -sLS https://dl.arkade.dev | sudo sh   # Moved automatically.
```

Install helm with `arkade get helm`.

You also need to add the helm chart repository:

```bash
$ helm repo add inlets-pro https://inlets.github.io/inlets-pro/charts/
$ helm repo update
```

### Install a client for a server using Auto TLS

If your exit server is using Auto TLS, then no additional configuration is required, because the inlets client will default to this mode. Auto TLS is where the server provides its own TLS certificate.

Install OpenFaaS which can be bundled with a Grafana dashboard:

```bash
arkade install openfaas

kubectl -n openfaas run \
  --image=stefanprodan/faas-grafana:4.6.3 \
  --port=3000 \
  grafana

kubectl -n openfaas expose pod grafana \
  --type=ClusterIP \
  --name=grafana
```

Now expose the Grafana dashboard via your pre-existing exit-server:

```bash
export IP="165.232.34.253"
export URL="wss://$IP:8123/connect"
export TOKEN_NAME="grafana-client-secret"
export SERVER_TOKEN="sTbFquOCHP9wLuAOM5E3jTDkygl9mEFDuWEBljY15EIUNwaB7UtVjOv0h9dGEA3L"
export NS="default"
kubectl create secret generic -n $NS \
  inlets-license --from-file license=$HOME/.inlets/LICENSE

kubectl create secret generic -n $NS \
  $TOKEN_NAME --from-literal token=$SERVER_TOKEN


helm upgrade --install grafana-tunnel inlets-pro/inlets-pro-client \
  --namespace $NS \
  --set tokenSecretName=$TOKEN_NAME \
  --set url=$URL \
  --set ports="3000" \
  --set upstream="grafana.openfaas" \
  --set autoTLS=true \
  --set fullnameOverride="grafana-tunnel"

echo Access Grafana via http://$IP:3000
kubectl logs deploy/grafana-tunnel
```

If you wish to disable public access to the forwarded ports, look at the reference documentation for inlets PRO for how to bind the data-plane to a local LAN or loopback adapter.

### Install a client for a server using an IngressController for TLS termination

If you are using an IngressController for TLS termination, then you need to disable the Auto TLS feature of inlets PRO (`--set autoTLS=false`).

Install OpenFaaS which bundles Prometheus:

```bash
arkade install openfaas
```

Install the client into the openfaas namespace:

```bash
export URL="wss://prometheus.example.com/connect"
export TOKEN_NAME="prometheus-client-secret"
export SERVER_TOKEN="sqbeua4TKwcNI0xrbGO9j2O3uPUX1t0PewqspESGEyQ5UJInurmzhwoZ"

kubectl create secret generic -n default \
  inlets-license --from-file license=$HOME/.inlets/LICENSE

kubectl create secret generic -n default \
  $TOKEN_NAME --from-literal token=$SERVER_TOKEN

helm upgrade --install prometheus-tunnel inlets-pro/inlets-pro-client \
  --namespace openfaas \
  --set tokenSecretName=$TOKEN_NAME \
  --set url=$URL \
  --set ports="9090" \
  --set upstream="prometheus" \
  --set autoTLS=false \
  --set fullnameOverride="prometheus-tunnel"

kubectl logs -n openfaas deploy/prometheus-tunnel
```

## Create a tunnel to expose an Ingress Controller

Let's say that you want to expose an Ingress Controller like Istio, Traefik or ingress-nginx. You can pre-create your exit-server for a stable IP address, and then connect deploy this chart to connect a client to the exit server and expose the Ingress Controller on the Internet.

Create an exit-server in TCP mode:

```bash
inletsctl create \
  --access-token-file ~/access-token \
  --region lon1 \
  --provider digitalocean
```

Note down the URL, TOKEN and IP address of the exit-server. 

Deploy the chart:

```bash
  export SERVER_TOKEN="" # Populate from above.
  export URL="wss://159.65.51.69:8123"  # Populate from above.
  export UPSTREAM="ingress-nginx-controller"
  export TOKEN_NAME="nginx-client-secret"

kubectl create secret generic -n default \
  inlets-license --from-file license=$HOME/.inlets/LICENSE

kubectl create secret generic -n default \
  $TOKEN_NAME --from-literal token=$SERVER_TOKEN

helm upgrade --install nginx-tunnel \
  inlets-pro/inlets-pro-client \
  --namespace default \
  --set tokenSecretName=$TOKEN_NAME \
  --set url=$URL \
  --set ports="80\,443" \
  --set upstream="$UPSTREAM" \
  --set autoTLS=true   \
  --set fullnameOverride="nginx-tunnel"
```

The IP will not show within your Kubernetes cluster, but will function as expected. All TCP traffic from ports 80 and 443 will be sent to the IngressController from the exit server.

You can also apply the same technique for Istio or Traefik. Bear in mind that you will need to alter the `--namespace` appropriately.

Create any A or CNAME records that you require with the public IP address of the exit-server, and then you can go ahead and use cert-manager to obtain TLS certificates from Let's Encrypt using a HTTP01 or DNS01 challenge.
