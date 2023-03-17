# The hard way to host an inlets TCP tunnel on Kubernetes

This post walks you through all the manual steps required to host an inlets TCP tunnel on a Kubernetes cluster.

## Who is this tutorial for?

This tutorial is not recommended for production, because we have better, cheaper and more convenient options available. It's really a tutorial for those who want to understand all the moving parts involved in creating and configuring Kubernetes objects.

If you're a service provider, or part of a SaaS company, don't follow these steps, but use one of the examples we provide below:

Instead, we've built a platform you can deploy to your cluster which makes it trivial to manage tunnels for customers: [Inlets Uplink for SaaS & Service Providers](https://inlets.dev/blog/2022/11/16/service-provider-uplinks.html)

If you're not a Service Provider or at a SaaS company, but need to host a bunch of TCP tunnels on your Kubernetes cluster, then you should use the [Helm chart for the Inlets Pro TCP server](https://github.com/inlets/inlets-pro/tree/master/chart/inlets-tcp-server)

If you're a personal user, you probably just want one or two tunnel servers, in which case we have a couple of tools that would probably suit you better:

* [inletsctl](https://github.com/inlets/inletsctl) - provision tunnel servers on a number of different public cloud platforms using userdata for the configuration
* [inlets-operator](https://github.com/inlets/inlets-operator) - a completely automated solution for getting public IPs for a local or private Kubernetes cluster

Following the steps in this tutorial will create a separate cloud LoadBalancer for each tunnel, which adds 20-30 USD / mo to your cloud bill per tunnel. Instead, we always use Ingress or an Istio Gateway which only needs a single LoadBalancer and keeps costs low.

## Deploy a TCP tunnel server

You'll need a Kubernetes cluster on a public cloud provider, but no domain name, no Ingress Controller, no Istio, etc.

### Create a service of type LoadBalancer and note down its IP address

The naming convention will be one namespace per customer, and the name will be repeated for each Kubernetes object, from the Service through to the Deployment.

In this example, the tunnel will be for a customer forwarding SSH and HTTP traffic using two different ports.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: customer1
```

### Create a secret with the token for the customer's tunnel to use

```bash
kubectl create secret generic tunnel \
    --from-literal=token=$(openssl rand -base64 32) \
    --namespace=customer1
```

### Deploy the dataplane service

Deploy a dataplane service, this will not be exposed on the Internet, you'll use this to access the services that the customer has forwarded over the tunnel:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tunnel
  namespace: customer1
  labels:
    app: 
spec:
  ports:
  - name: postgres
    port: 5432
    protocol: TCP
    targetPort: 5432
  selector:
    app.kubernetes.io/name: tunnel
  type: ClusterIP
status: {}
```

### Create the LoadBalancer service

Create and apply the LoadBalancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tunnel-lb
  namespace: customer1
  labels:
    app: 
spec:
  ports:
  - name: control
    port: 8123
    protocol: TCP
    targetPort: 8123
  selector:
    app.kubernetes.io/name: tunnel
  type: LoadBalancer
status: {}
```

Wait until the LoadBalancer has an IP address, do not proceed until you have it.

### Create a Deployment for the tunnel server

Create a Deployment for the `inlets-pro tcp server`, and insert the IP address in the `--auto-tls-san=` flag.

Note for AWS users, you'll have to find the tunnel's DNS entry instead of its IP, so you will need to eyeball the results of `kubectl get svc -n customer1 -o wide` and copy the `EXTERNAL-IP` column to `export AUTO_TLS_SAN=""`.

```yaml
export AUTO_TLS_IP=$(kubectl get svc tunnel-lb -n customer1 -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

cat >> tunnel-dep.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tunnel
  namespace: customer1
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: tunnel
  template:
    metadata:
      labels:
        app.kubernetes.io/name: tunnel
    spec:
      containers:
      - args:
        - tcp
        - server
        - --token-file=/var/inlets/token
        - --control-port=8123
        - --auto-tls
        - --auto-tls-san=$AUTO_TLS_IP
        image: ghcr.io/inlets/inlets-pro:0.9.17
        imagePullPolicy: IfNotPresent
        name: server
        resources:
          limits:
            memory: 128Mi
          requests:
            cpu: 25m
            memory: 25Mi
        volumeMounts:
        - mountPath: /var/inlets/
          name: inlets-token-volume
          readOnly: true
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      volumes:
      - name: inlets-token-volume
        secret:
          defaultMode: 420
          secretName: tunnel
status: {}

EOF

kubectl apply -f tunnel-dep.yaml
```

### Deploy a test service on the client's machine

```bash
export PASSWORD="8cb3efe58df984d3ab89bcf4566b31b49b2b79b9"

docker run --rm --name postgres \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=8cb3efe58df984d3ab89bcf4566b31b49b2b79b9 \
  -ti postgres:latest
```

### Connect the inlets-pro client on the client's machine

Construct the client command:

```bash
export NAMESPACE=customer1

export TUNNEL_IP=$(kubectl get svc tunnel-lb -n $NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
export TUNNEL_TOKEN=$(kubectl get secret tunnel -n $NAMESPACE -o jsonpath="{.data.token}" | base64 --decode)

echo inlets-pro tcp client \
    --url wss://$TUNNEL_IP:8123 \
    --token \"$TUNNEL_TOKEN\" \
    --upstream 127.0.0.1 \
    --port 5432 \
    --auto-tls
```

Connect to the service over the tunnel, by running a command in-cluster:

```bash
export PASSWORD="8cb3efe58df984d3ab89bcf4566b31b49b2b79b9"

kubectl run -i -t psql \
    --rm \
    -n default \
    --image-pull-policy=IfNotPresent \
    --env PGPORT=5432 \
    --env PGPASSWORD=$PASSWORD --rm \
    --image postgres:latest -- psql -U postgres -h tunnel.customer1

CREATE TABLE devices (name TEXT, IPADDRESS varchar(15));
\dt
```

To add additional customers, just adapt as necessary, with a new namespace, secret, private ClusterIP service and LoadBalancer service and deployment for each tunnel.

## Wrapping up

We've now deployed an inlets tunnel server to our Kubernetes cluster, connected a customer to it, we then accessed the tunneled service through `kubectl run`.

This tutorial was about showing you each individual part of the deployment, and is not how we recommend running inlets-pro in production. Instead, you should see the two options in the introduction.

