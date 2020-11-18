## inlets-pro chart

Install an inlets PRO server as an exit-server to run within a Pod.

inlets can be exposed 

## Getting started

You will need a domain available and two other charts:

### Install pre-reqs

You can run this on any Intel or ARM cluster.

Download [arkade](https://get-arkade.dev/), or use helm to install pre-reqs

* Install cert-manager - (`arkade install cert-manager`)
* Install ingress-nginx - (`arkade install ingress-nginx`)

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

### Generate a token for your inlets server

```bash
export TOKEN=$(head -c 16 /dev/random | shasum|cut -d" " -f1)
kubectl create secret generic inlets-pro-secret --from-literal token=$TOKEN

# Save a copy for later
echo $TOKEN > token.txt
```

### Install the inlets-pro chart

The chart will deploy two services, an Ingress and a deployment for the inlets-pro server.

* `prometheus-tunnel-control-plane` - a service exposed by Ingress, for the websocket of inlets PRO
* `prometheus-tunnel-data-plane` - a local service to access Prometheus from within the cluster

Edit `values.yaml`:

Make any changes you need.

```bash
export DOMAIN="prometheus.example.com"

git clone https://github.com/inlets/inlets-pro
cd inlets-pro/chart

helm upgrade --install prometheus-tunnel ./inlets-pro \
  --set domain $DOMAIN
```

### Now connect your client on your computer.

Run Prometheus locally as a Docker container for testing:

```bash
docker run -p 9090:9090 -ti prom/prometheus:latest
```

Now connect your inlets-pro client:

```bash
export DOMAIN="prometheus.example.com"
export TOKEN=$(cat token.txt)
inlets-pro client --url wss://$DOMAIN/connect \
  --token $TOKEN \
  --license-file ~/LICENSE \
  --port 9090 \
  --auto-tls=false \
  --upstream 127.0.0.1
```

### Now access the tunnelled Prometheus from the Kubernetes cluster

```bash
kubectl run alpine -t -i --image alpine:3.12 /bin/sh
apk add curl

curl prometheus-tunnel-inlets-pro-data-plane:9090
```

You can also use `kubectl port-forward` to view the tunneled service:

```bash
kubectl port-forward \
  svc/prometheus-tunnel-inlets-pro-data-plane 9091:9090

echo Open: http://127.0.0.1:9091
```

## Other configuration

See values.yaml for additional settings.

Expose Grafana instead:

```yaml
dataPlane:
  type: ClusterIP
  ports:
  - targetPort: 3000
    protocol: TCP
    name: grafana-http
    port: 3000
```

Expose two ports instead of one:

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
    name: prom-http
    port: 9090
```

In a few moments, you'll get a public IP for the LoadBalancer for the data-plane.

The alternative approach to adding a LoadBalancer to expose the workload from the Kubernetes cluster is to add an Ingress definition for the `prometheus-tunnel-inlets-pro-data-plane` service instead. This way you can save on costs and re-use your existing IngressController.
