## Run an inlets PRO client in your Kubernetes cluster

An inlets PRO client can be used to tunnel a service from a local cluster to a remote network or remote Kubernetes cluster.

You should decide whether you want to expose the remote service to the world, or to just the local area network of the exit-server.

### Pre-reqs:

* An inlets PRO server set up manually, via inletsctl, or using the inlets-pro (server) chart.

You'll need the helm binary, the easiest way to get this is via arkade:

```bash
curl -sL https://dl-get-arkade.dev | sudo sh
chmod +x arkade
sudo mv arkade /usr/local/bin/

arkade get helm
arkade get helm [--version VER]
```

### Install a client for a server using auto-tls

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
  inlets-license --from-file license=$HOME/LICENSE

kubectl create secret generic -n $NS \
  $TOKEN_NAME --from-literal token=$SERVER_TOKEN

git clone https://github.com/inlets/inlets-pro
cd inlets-pro/chart

helm upgrade --install grafana-tunnel ./inlets-pro-client \
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

### Install a client for a server using cert-manager for TLS termination

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
  inlets-license --from-file license=$HOME/LICENSE

kubectl create secret generic -n default \
  $TOKEN_NAME --from-literal token=$SERVER_TOKEN

git clone https://github.com/inlets/inlets-pro
cd inlets-pro/chart

helm upgrade --install prometheus-tunnel ./inlets-pro-client \
  --namespace openfaas \
  --set tokenSecretName=$TOKEN_NAME \
  --set url=$URL \
  --set ports="9090" \
  --set upstream="prometheus"
  --set autoTLS=false \
  --set fullnameOverride="prometheus-tunnel"

kubectl logs -n openfaas deploy/prometheus-tunnel
```

