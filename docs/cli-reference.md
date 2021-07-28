# inlets-pro CLI reference

There are two components to inlets-pro, the server and the client.

This reference guide is designed for self-service, but customers of OpenFaaS Ltd can request hands-on support and training. Just email [contact@openfaas.com](mailto:contact@openfaas.com) for more. Business customers are entitled to free support, [find out more](https://inlets.dev/).

Community and personal users can also find help in the [OpenFaaS Slack community](https://slack.openfaas.io/), in the #inlets channel.

## Contents:

* Working with MacOS, Linux, and Windows
* Topology
* HTTP or TCP tunnels?
* Configure the inlets-pro tcp client
* Configure the inlets-pro tcp server
* Configure the inlets-pro http client
* Configure the inlets-pro http server
* Troubleshooting
* Working with Kubernetes

## Working with MacOS, Linux, and Windows

The examples given in the documentation are valid for all three operating systems and use bash as a syntax.

Windows users can use either Windows Subsystem for Linux (WSL) or [Git bash](https://git-scm.com/downloads), this is the simplest way to make all commands compatible.

The client and server component are packaged in the same `inlets-pro` binary and can be run as:

* A process on MacOS, Linux, Windows on ARM or Intel architecture
* As a Docker container with docker, or Kubernetes as a Pod on ARM or Intel architecture

## Topology

inlets is not about exposing services on the Internet, it's about making one service available within another network. What, where and how accessible that network is, is purely up to you.

Consider a typical example that you may use a SaaS tunnel for:

![Quick HTTP tunnel](https://inlets.dev/images/quick.png)
> HTTP tunnels

Here, we have a private Node.js server running on localhost and port 3000, we want to expose that on the Internet with a TLS certificate.

### Split-plane configuration

inlets has two TCP ports, both of which can be exposed on various interfaces. By default, both ports are exposed on on all available adapters, i.e. `0.0.0.0` (IPv4) and `::` (IPv6).

The first TCP port is called the Control Plane, the Control Plane is a websocket secured with TLS, that the inlets client connects to, in order to establish the tunnel.

The Data Plane is one or more TCP ports that are exposed on the server, which map back to a private service on the client's end.

To replace the role of a site-to-site VPN or Direct Connect, you can expose the Control Plane publicly on `0.0.0.0`, and the data-plane on either `127.0.0.1` or one of the other internal interfaces i.e. `10.0.0.10`, which is not accessible from the Internet.

### What about High Availability?

It's possible to run multiple inlets client processes and have them connect to the same server. The server will load-balance incoming requests and distribute them between each client.

The server can also be made High Availability, by running more than one copy. You could run two public Virtual Machines (VMs) and then add a VIP/FIP or Load Balancer in front. In this way, the pair of inlets servers work in an active-active configuration, and if one VM locks up or goes down, then the other will continue to serve traffic.

## HTTP or TCP tunnels?

A HTTP tunnel is most useful for HTTP services and APIs. In this mode, a single tunnel can use the HTTP Host header to expose multiple different services using a DNS name and a single port.

A TCP tunnel is a pass-through proxy for any TCP service. Use a TCP tunnel if you want to run a reverse proxy on the client's machine, or if you have traffic that is non-HTTP like a database, RDP, SSH and so on.

Any traffic that is sent over an inlets tunnel is encrypted, even if the underlying protocol does not support encryption. This is because the data is encapsulated and send over a link with TLS enabled.

### Configure a TCP client

The client component connects to an inlets server and then routes incoming requests to a private service. The client can run on the same host as your private service, or run on another host and act as gateway.

### Configure the license key

The license terms of inlets-pro require that both the inlets client and server have a valid license, only the client requires to have the license configured.

The default location for a license is `$HOME/.inlets/LICENSE`, you can also override the license with the `--license-file` or `--license` flag to pass a literal value.

## Setup a TCP client

### Set the upstream

The upstream is where the client should send traffic, when it receives requests on one of the ports from the server.

```sh
export UPSTREAM="127.0.0.1"
inlets-pro tcp client \
  --upstream $UPSTREAM
```

You can pass the IP address or DNS name of a service available on the local network of the client.

```sh
export UPSTREAM="192.168.0.101"
inlets-pro tcp client \
  --upstream $UPSTREAM
```

When running inside a Kubernetes cluster as a Pod, the inlets client can use the DNS name of services.

```sh
export UPSTREAM="traefik.kube-system"
inlets-pro tcp client \
  --upstream $UPSTREAM
```

In TCP mode, all traffic is passed through without inspection or modification, for this reason, only one `--upstream` server is possible for TCP tunnels.

### Set the ports for the tunnel `--ports` / `--port`

Expose ports on the tunnel server, from the client with one of the following:

```sh
--port 80
-p 80
```

Or give the flag multiple times:

```sh
--port 80 --port 443
```

Or use `--ports` and a comma-separated list:

```sh
--ports 80,443
```

### Connect to the remote host (server) with `--url`

inlets-pro uses a websocket for its control plane on port `8123` by default with *automatic TLS* configured.

* Automatic TLS with `auto tls`

    In this mode the client and server will negotiate TLS through the use of a generate Certificate Authority (CA) and encrypt all traffic automatically.

    This is the default option, connect with `wss://` and the IP of the remote machine

    `--url wss://remote-machine:8123`

    The control-port of 8123 is used for auto-tls.

* External TLS

    In this mode, you are providing your own TLS certificate or termination through a gateway, Kubernetes Ingress Controller, reverse-proxy or some other kind of product.

    Turn auto-TLS off, and use port 443 (implicit) for the control-plane.

    `--url wss://remote-machine`

    You must also pass the `--auto-tls=false` flag

* No TLS or encryption

    This mode may be useful for testing, but is not recommended for confidential use.

    `--url ws://remote-machine:8123`

    Use port `8123` for the control-plane and `ws://` instead of `wss://`

#### Set the authentication token `--token`

The `inlets-pro tcp server` requires a token for authentication to make sure that the client is genuine. It is recommended to combine the use of the token with auto-tls or external TLS.

You can create your own token, or generate one with bash:

```sh
export TOKEN="$(head -c 16 /dev/urandom |shasum|cut -d'-' -f1)"
echo $TOKEN
```

Now pass the token via `--token $TOKEN`.

### Generate a systemd unit file for the client

Add `inlets-pro tcp client --generate=systemd` to generate a system unit file.

You'll need all the parameters that you would use to run the client, so don't leave any off.

For example:

```bash
export TOKEN="TOKEN_HERE"
export UPSTREAM="127.0.0.1"

inlets-pro tcp client \
  --upstream $UPSTREAM \
  --license-file /var/lib/inlets-pro/LICENSE \
  --tcp-ports "80,443" \
  --url "wss://167.99.90.104:8123" \
  --token $TOKEN \
  --generate=systemd
```

### Configure the TCP server

The inlets-pro tcp server begins by opening a single TCP port `8123` for the control-plane, this is port `8123`. The port can be changed if required, by passing the `--control-port` flag.

Additional ports are opened at runtime by the inlets-server for the data-plane. These ports must be advertised by the client via the `--tcp-ports` flag.

#### Start with auto-tls

Auto-TLS will create a Certificate Authority CA and start serving it via the control-plane port.

You can view it like this:

```sh
curl -k -i http://localhost:8123/.well-known/ca.crt
```

An authentication token is also required which must be shared with the client ahead of time.

#### Set the `--auto-tls-san` name

The `--auto-tls-san` sets the subject-alternative-name (SAN) for the TLS certificate that is generated by the server.

You can use the public IP address of the inlets-server, or a DNS record.

* Public IP

    ```sh
    --auto-tls-san 35.1.25.103
    ```

* DNS A or CNAME record

    ```sh
    --auto-tls-san inlets-control-tunnel1.example.com
    ```

    In this example `inlets-control-tunnel1.example.com` will resolve to the public IP, i.e. `35.1.25.103`

#### Use a pre-supplied, or self-signed certificate

You can use a TLS certificate with the inlets PRO server obtained from a third-party tool such as [certbot](https://certbot.eff.org), or your own Public Key Infrastructure (PKI).

If you wanted to use an exit-server with a public IP, you can create a DNS A record for it before configuring certbot or another tool to fetch a TLS certificate for you from LetsEncrypt. If you don't want to set up a separate DNS record, then you can get an automated one from [xip.io](http://xip.io) such as `104.16.182.15.xip.io` or `104.16.182.15.xip.io`, where your public IP is `104.16.182.15`.

The below instructions are for a DNS name on a local network `space-mini.local`, but you can customise the example.

For the server:

```bash
export AUTH_TOKEN="test-token"

inlets-pro tcp server \
    --tls-key server.key \
    --tls-cert server.cert \
    --auto-tls=false \
    --token "${AUTH_TOKEN}"
```

Note that you need to supply a server.key and server.cert file, and that you need to disable `--auto-tls`.

On your client, add the certificate to your trust store, or add its issuer to your trust store, then run:

```bash
export AUTH_TOKEN="test-token"

inlets-pro tcp client \
  --tcp-ports 2222 \
  --license-file $HOME/.inlets/LICENSE \
  --token "${AUTH_TOKEN}" \
  --url wss://space-mini.local:8123 \
  --auto-tls=false
```

Note that you must turn off `--auto-tls`, so that the client does not attempt to download the server's generated CA.

#### Want to generate your own TLS certificate for testing?

Make sure that you set the auto-tls-san or TLS SAN name to the hostname that the client will use to connect.

Generate a new key:

```bash
openssl genrsa -out server.key 2048
```

Generate a certificate signing request (CSR):

When promoted, do not enter a challenge key. If your hostname is `space-mini.local`, then enter that as the `Common Name`.

```bash
openssl req -new -key server.key -out server.csr
```

Obtain the server certificate from the CSR:

```bash
openssl x509 -req -sha256 -days 365 -in server.csr -signkey server.key -out server.cert
```

You will receive an error on your client such as:

```
ERRO[0000] Failed to connect to proxy. Empty dialer response  error="x509: certificate signed by unknown authority"
```

Therefore, place the server.cert file in your trust store on your client and set the trust policy to "Always trust".

If you are thinking about using self-signed certificates, then the automatic TLS option is already built-in and is easier to use. 

#### Set the authentication token `--token`

The inlets-pro tcp server requires a token for authentication to make sure that the client is genuine. It is recommended to combine the use of the token with auto-tls or external TLS.

You can create your own token, or generate one with bash:

```sh
export TOKEN="$(head -c 16 /dev/urandom |shasum|cut -d'-' -f1)"
echo $TOKEN
```

Now pass the token via `--token $TOKEN`.

### Configure a http tunnel

The HTTP mode of inlets PRO is suitable for REST / HTTP traffic. Use it when you want to add TLS termination on the exit-server without running a reverse-proxy in the client's network.

Just like a TCP tunnel, a HTTP tunnel has two TCP ports, one for the control-plane and one for the data-plane.

For more information, see the help commands:

* See also: `inlets-pro http server --help`
* See also: `inlets-pro http client --help`

### Configuring TLS for the HTTP server's data-plane

The control-plane will use Auto-TLS by default, but the data-plane does not.

#### Use Let's Encrypt to obtain a TLS certificate for the data plane

inlets PRO HTTP tunnels are able to obtain TLS certificates from Let's Encrypt for the data-plane. In this mode, you'll find that the server exposes port 80 and 443 in order to process a HTTP01 challenge.

Three additional fields enable the client to obtain a TLS certificate for the data-plane:

```bash
  --letsencrypt-domain stringArray   obtain TLS certificates from Let's Encrypt for the following domains using a HTTP01 challenge
  --letsencrypt-email string         email address to be used with Let's Encrypt
  --letsencrypt-issuer string        obtain TLS certificates from the prod or staging Let's Encrypt issuer (default "prod")
```

For example, to setup a HTTP tunnel to a LetsEncrypt-enabled exit-server, you can use the following command:

```bash
export IP=$(curl -sfSL https://checkip.amazonaws.com)
export TOKEN=""

inlets-pro http server \
    --auto-tls \
    --control-port 8123 \
    --auto-tls-san $IP \
    --letsencrypt-domain prometheus.example.com \
    --letsencrypt-email user@example.com \
    --token TOKEN
```

Then create a DNS A record mapping `prometheus.example.com` to the public IP of the server.

You can pass the `--letsencrypt-domain` flag multiple times to obtain TLS certificates for multiple domains.

Then on the client side, you will run a command such as:

```bash
export IP="SERVER_IP"
export TOKEN=""

inlets-pro http client \
    --auto-tls \
    --url wss://$SERVER_IP:8123 \
    --upstream prometheus.example.com=http://127.0.0.1:9090 \
    --token TOKEN
```

The `--upstream` flag can accept multiple DNS name mappings for instance: `prometheus.example.com=http://127.0.0.1:9090,grafana.example.com=http://127.0.0.1:3000`

Follow a tutorial: [Get a secure HTTPS tunnel with Let's Encrypt](https://inlets.dev/blog/2021/02/11/secure-letsencrypt-tunnel.html)

## Working with Kubernetes

You can deploy an inlets server or client as a Pod using the [inlets-pro helm chart](/chart/).

For a server, you can expose its control and / or data plane for external access:

* As a Service type LoadBalancer

    It will gain its own IP address, and you'll pay for one cloud load-balancer per tunnel.

* As a Service type NodePort

    You will have to use high, non-standard TCP ports and may run into issues with manually managing the mapping of ports. This adds no cost to the Kubernetes cluster. You can also use auto-TLS for the control-plane.

* As an Ingress definition

    The Ingress definition is the most advanced option and works without auto-TLS. For each inlets-server you need to create a separate Kubernetes Ingress definition and domain name.

    Clients will connect to the domain name and your IngressController will be responsible for configuring TLS either via LetsEncrypt or your own certificate store.

* Split-plane with an Ingress definition

    In this configuration, only the inlets-pro control plane is exposed (usually port `8123`) with a publicly accessible address, and the data-plane is not exposed outside the network. This can be achieved through the use of two separate ClusterIP services.

    This configuration is ideal for command and control. The private network will be able to traverse firewalls and NAT to connect to the remote inlets-pro tcp server, but only internal services within the Kubernetes cluster can connect to the tunnelled service.

    See [split-plane-server.yaml](../artifacts/split-plane-server.yaml) as an example.

### Pod / Service / Deployment definitions

You can use the sample artifact for the [client.yaml](../artifacts/client.yaml) or [server.yaml](../artifacts/server.yaml)

There is also a [helm chart for the client and server](/chart/).

## Troubleshooting

* You have a port permission issue for low ports `< 1024` such as `80`

    The reason for this error is that the inlets-pro Docker image is set to run as a non-root user and non-root users are not allowed to bind to ports below 1024.

    There are two ways around this, the first being that you perhaps don't need to bind to that low port. Docker, Kubernetes and inlets-pro all allow for port remapping, so there should be no reason for a you to need to bind directly to port 80 in a service.

    Try adding each port to the Kubernetes container spec with your override:

    ```yaml
    ports:
    - name: http
      containerPort: 8080
      protocol: TCP
    ```

    The second solution is to change the security context so that your inlets server runs as root. You may also need to run the pod as a root user by [editing the security context of the Pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

    Further more, if you are not a Kubernetes user, but using Docker, you can derive a new image from our upstream image and override the user there:

    ```Dockerfile
    FROM inlets/inlets-pro:TAG

    USER root
    ```

    For manual use with Docker, you can also set a non-root user via the `--user root` / `--user 0` flag: `docker run --uid 0 --name inlets-pro-root-server -ti inlets/inlets-pro:TAG server`

* The client cannot write the auto-TLS certificate to `/tmp/` due to a read-only filesystem

    Add a tmpfs mount or an empty-dir mount to the Pod Spec at `/tmp/`

    ```yaml
    volumes:
    - name: tmp-cert
    emptyDir: {}
    ```

    To the container spec:

    ```yaml
    volumeMounts:
    - mountPath: /tmp
        name: tmp-cert
    ```

* `apiVersion: apps/v1beta1` vs `apiVersion: apps/v1`

    If you're on a very old version of Kubernetes, then the `apps/v1` apiVersion may need to be changed to `apps/v1beta1`. Feel free to contact technical support for more hands-on help.

* Multiple inlets tunnels

    You can run as many inlets tunnels as you like, both client and server Pods. Make sure that each is named appropriately.

    The server will require its own Service and Deployment.

    The client just requires a Deployment.

    I.e. replace `inlets-server` with `inlets-server-tunnel1` and so forth.

    If you are managing several tunnels, then feel free to contact OpenFaaS Ltd about an automation solution.
