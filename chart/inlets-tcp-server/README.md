## Use your Kubernetes cluster for exit-servers

This chart installs the inlets Pro server in TCP mode. It runs the inlets server process as a Pod within your Kubernetes cluster.

You can use this to avoid creating individual exit-server VMs, or to connect a number of services into to a public Kubernetes cluster. It's up to you to decide whether you want to access any tunneled services from the Internet, or from within the cluster.

> If you are wanting to test inlets Pro TCP tunnel servers in Kubernetes, without a domain and without configuring TLS and Ingress, you can try out: [The hard way to host an inlets TCP tunnel on Kubernetes](../../docs/inlets-tcp-server-hard-way.md)

## Getting started

In this tutorial, you'll learn how to set up a tunnel for a Prometheus service running on a private network. It will be tunneled to your Kubernetes cluster through an inlets server running in a Pod. [Prometheus](https://prometheus.io) is a time-series database used for monitoring microservices. It is assumed that you have one or more Prometheus instances that you want to monitor from a cloud Kubernetes cluster.

You will need a cloud Kubernetes cluster and access to a sub-domain available and its DNS control-panel.

### Install the prerequisites

You can run this on any Intel or ARM cluster.

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

#### Install nginx-ingress

```bash
$ arkade install nginx-ingress
```

#### Install cert-manager

[cert-manager](https://cert-manager.io/), can obtain TLS certificates from LetsEncrypt through NginxIngress.

```bash
$ arkade install cert-manager
```

It is assumed that you installed `kubectl` when you created your Kubernetes cluster, otherwise run `arkade get kubectl`.

### Install an Issuer

Create a production certificate issuer issuer-prod.yaml, similar to the staging issuer you produced earlier. Be sure to change the email address to your email.

```bash
export DOMAIN="prometheus.example.com"
export EMAIL="webmaster@$DOMAIN"

cat > issuer-prod.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-prod
  namespace: default
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - selector: {}
      http01:
        ingress:
          class: nginx
EOF
```

Then run:

```bash
kubectl apply -f issuer-prod.yaml
```

> Note: if you plan to run many tunnels, each with their own certificate, then you may wish to configure the cert-manager Issuer to use a DNS01 challenge. See also: [Configuring DNS01 Challenge Provider ](https://cert-manager.io/docs/configuration/acme/dns01/)

### Generate a token for your prometheus inlets-pro server

```bash
# Generate a random password
export TOKEN=$(head -c 16 /dev/random | shasum|cut -d" " -f1)

# Save a copy for later
echo $TOKEN > prometheus-token.txt

# Create a secret in the cluster for the tunnel server
kubectl create secret generic prometheus-tunnel-token \
  --from-literal token=$TOKEN
```

### Install the inlets-pro TCP server chart

Edit `values.yaml`:

Make any changes you need.

```bash
export DOMAIN="prometheus.example.com"
export TOKEN="prometheus-tunnel-token"

helm upgrade --install prometheus-tunnel inlets-pro/inlets-tcp-server \
  --set ingress.domain=$DOMAIN \
  --set tokenSecretName=$TOKEN
```

> Note: replace the domain with a domain you own.

The chart will deploy two Kubernetes services, an Ingress record and a Deployment to run the inlets-pro server process.

* `prometheus-tunnel-control` - a service exposed by Ingress, for the websocket of inlets Pro (usually port 8123)
* `prometheus-tunnel-data` - a local service to access Prometheus from within the cluster (usually 9090)

### Now connect your client on your computer.

You can now connect Prometheus from wherever you have it running, whether that's in a container, on your system as a normal process, or within a Kubernetes cluster.

Let's run a Prometheus container with Docker, so that we can connect it to the inlets server quickly.

```bash
docker run --name prometheus \
  -p 9090:9090 \
  -d prom/prometheus:latest
```

> Note: you can remove this container later with `docker rm -f prometheus`

You will need the tunnel token to connect the inlets-pro client. If you saved a copy of the token you can used that. Otherwise it can be retrieved from the cluster:

```bash
kubectl get secret -n default prometheus-tunnel-token -o jsonpath="{.data.token}" | base64 --decode > prometheus-token.txt
```

Now connect your inlets-pro client:

```bash
export DOMAIN="prometheus.example.com"
export TOKEN_FILE="./prometheus-token.txt"
inlets-pro tcp client --url wss://$DOMAIN/connect \
  --token-file $TOKEN_FILE \
  --license-file ~/LICENSE \
  --port 9090 \
  --auto-tls=false \
  --upstream 127.0.0.1
```

We use a value of `--upstream 127.0.0.1` since the Prometheus container was exposed on 127.0.0.1 in the previous `docker run` command. If you were running the inlets client as a Pod, then you would use something like `--upstream prometheus` instead. You can also put an IP address attached to another computer in the upstream field. It just needs to be accessible from the client.

### Now access the tunnelled Prometheus from the Kubernetes cluster

We haven't exposed the Prometheus service on the Internet for general consumption, so let's access it through its private ClusterIP which was deployed through the helm chart.

Run a container with curl installed.

```bash
kubectl run -t -i curl --rm --image ghcr.io/openfaas/curl:latest /bin/sh 
```

Now access the tunneled service via curl:

```bash
curl prometheus-tunnel-data:9090
```

You can also use `kubectl port-forward` to view the tunneled service:

```bash
kubectl port-forward \
  svc/prometheus-tunnel-data 9091:9090 

echo Open: http://127.0.0.1:9091
```

### Install multiple tunnels
To deploy multiple tunnel servers with the Helm chart some steps will need to be repeated for each tunnel:

- Create a secret for the tunnel.
- Create a `values.yaml` file with the helm parameter configuration.
- Deploy the tunnel server using Helm.

In this example we will setup a second tunnel for a PostgreSQL server running on a private network.

Create a new secret for the PostgreSQL tunnel:

```bash
# Generate a random password
export TOKEN=$(head -c 16 /dev/random | shasum|cut -d" " -f1)

# Save a copy for later
echo $TOKEN > postgres-token.txt

# Create a secret in the cluster for the tunnel server
kubectl create secret generic postgres-tunnel-token \
  --from-literal token=$TOKEN
```

Create a values file `postgres-values.yaml` with the chart configuration parameters for the tunnel:

```yaml
export DOMAIN=postgres.example.com

cat >> postgres-values.yaml <<EOF
dataPlane:
  type: ClusterIP
  ports:
  - targetPort: 5432
    protocol: TCP
    name: postgresql
    port: 5432

ingress:
  domain: $DOMAIN

tokenSecretName: postgres-tunnel-token
EOF
```

Deploy the tunnel using the `postgres-values.yaml` file:

```bash
helm upgrade --install postgres-tunnel inlets-pro/inlets-tcp-server \
  --values=postgres-values.yaml
```

Run a postgress container on you local system:

```bash
export PASSWORD="8cb3efe58df984d3ab89bcf4566b31b49b2b79b9"

docker run --rm --name postgres \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=8cb3efe58df984d3ab89bcf4566b31b49b2b79b9 \
  -ti postgres:latest
```

Connect the inlets-pro client:

```bash
export DOMAIN="postgres.example.com"
export TOKEN=$(kubectl get secret -n default postgres-tunnel-token -o jsonpath="{.data.token}" | base64 --decode)

inlets-pro tcp client --url wss://$DOMAIN/connect \
  --token $TOKEN \
  --license-file ~/LICENSE \
  --port 5432 \
  --auto-tls=false \
  --upstream 127.0.0.1
```

Connect to postgress from within the cluster:

```bash
kubectl run -i -t psql \
  --env PGPORT=5432 \
  --env PGPASSWORD=${PASSWORD} --rm \
  --image postgres:latest -- psql -U postgres -h postgres-tunnel-data
```

Try a command such as `CREATE database websites (url TEXT)`, `\dt` or `\l`.

## Other configuration

See values.yaml for additional settings.

Tunnel Grafana instead of Prometheus:

```yaml
dataPlane:
  type: ClusterIP
  ports:
  - targetPort: 3000
    protocol: TCP
    name: grafana-http
    port: 3000
```

Tunnel two ports instead of just one:

```yaml
dataPlane:
  type: ClusterIP
  ports:
  - targetPort: 22
    protocol: TCP
    name: ssh
    port: 22
  - targetPort: 8080
    protocol: TCP
    name: web-api
    port: 8080
```

If you want to make your tunnelled workloads available from the public Internet, then you can alter the service into a LoadBalancer:

Make the following edit:

```yaml
dataPlane:
  type: LoadBalancer
  ports:
  - targetPort: 9090
    protocol: TCP
    name: prometheus
    port: 9090
```

In a few moments, you'll get a public IP for the LoadBalancer for the data-plane. If you don't want to pay for individual LoadBalancers, you could consider using a NodePort, with a static port number assignment for each service you want to expose. NodePorts are harder to manage, but usually have no additional cost if your Kubernetes nodes have public IP addresses.

The alternative approach to adding a LoadBalancer to expose the workload from the Kubernetes cluster is to add an Ingress definition for the `prometheus-tunnel-inlets-pro-data-plane` service instead. This way you can save on costs by only paying for a single LoadBalancer and IP, and multiplexing the various services through your IngressController.

