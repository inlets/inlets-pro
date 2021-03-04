# inlets-pro CLI reference

There are two components to inlets-pro, the server and the client.

This reference guide is designed for self-service, but customers of OpenFaaS Ltd can request hands-on support and training. Just email sales@openfaas.com for more.

## Contents:

* Working with MacOS, Linux, and Windows
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

### Configure the inlets-pro tcp client

The client component connects to an inlets server and then routes incoming requests to a private service. The client can run on the same host as your private service, or run on another host and act as gateway.

#### Set the license

The license terms of inlets-pro require that both the inlets client and server have a valid license, only the client requires to have the license configured.

You can configure the license in one of two ways:

* From a file `--license-file`

    ```sh
    # Assume a file of `pro-license.txt` with the license key, no new lines or whitespace
    inlets-pro tcp client \
    --license-file $HOME/.inlets/LICENSE
    ```

* literal flag `--license`

    ```sh
    inlets-pro tcp client \
    --license "VALUE_HERE"
    ```

* literal flag with environment variable

    ```sh
    export INLETS_LICENSE="LICENSE_KEY_VALUE"
    inlets-pro tcp client \
    --license="$INLETS_LICENSE"
    ```

* literal flag with environment variable set in your bash profile

    You can also set the INLETS_LICENSE file for each terminal session by editing `$HOME/.bash_profile`

    Add a line for:

    ```sh
    export INLETS_LICENSE="LICENSE_KEY_VALUE"
    ```

### Set the upstream

The upstream is where the client should send traffic, when it receives requests on one of the ports from the server.

```sh
export UPSTREAM="127.0.0.1"
inlets-pro tcp client \
  --upstream $UPSTREAM
```

This can be the local machine, a Kubernetes service, or any reachable hostname:

```sh
export UPSTREAM="traefik.kube-system"
inlets-pro tcp client \
  --upstream $UPSTREAM
```

### Set the ports for the tunnel `--ports` / `--port` (0.7.0 and newer)

Expose ports on the tunnel server, from the client with one of the following:

```
--port 80
-p 80
--port 80 --port 443
```

Or

```
--ports 80,443
```

### Set the TCP ports for the tunnel `--tcp-ports` (0.6.0 and older)

The client will advertise which TCP ports it requires the server to open, this is done via the `--tcp-ports` flag

* A single alternative HTTP port

    `--tcp-ports=8080`

* Nginx, or a HTTP service with TLS

    `--tcp-ports=80,443`

### Connect to the remote host (server) with `--url` (0.7.0 and newer)

inlets-pro uses a websocket for its control plane on port `8123` by default and adds automatic TLS. This is an optional feature.

* Automatic TLS with `auto tls`

    In this mode the client and server will negotiate TLS through the use of a generate Certificate Authority (CA) and encrypt all traffic automatically.

    This is the default option, connect with `wss://` and the IP of the remote machine

    `--url wss://remote-machine:8123/connect`

    The control-port of 8123 is used for auto-tls.

* External TLS

    In this mode, you are providing your own TLS certificate or termination through a gateway, IngressController, reverse-proxy or some other kind of product.

    Turn auto-TLS off, and use port 443 (implicit) for the control-plane.

    `--url wss://remote-machine/connect`

    You must also pass the `--auto-tls=false` flag

* No TLS or encryption

    This mode may be useful for testing, but is not recommended for confidential use.

    `--url ws://remote-machine:8123/connect`

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

Add "inlets-pro tcp client --generate=systemd" to generate a system unit file for your client along with all the other required parameters.

For example:

```bash
export TOKEN="auth token"
export UPSTREAM="127.0.0.1"

inlets-pro tcp client \
  --upstream $UPSTREAM \
  --license-file /var/lib/inlets-pro/LICENSE \
  --tcp-ports "80,443" \
  --url "wss://167.99.90.104:8123/connect" \
  --token $TOKEN \
  --generate=systemd
```

### Configure the inlets-pro tcp server

The inlets-pro tcp server begins by opening a single TCP port for the control-plane, this is port `8123`, but you can customise it if required.

Additional ports are opened at runtime by the inlets-server for the data-plane. These ports must be advertised by the client via the `--tcp-ports` flag.

#### Start with auto-tls

Auto-TLS will create a Certificate Authority CA and start serving it via the control-plane port.

You can view it like this:

```sh
curl -k -i http://localhost:8123/.well-known/ca.crt
```

A token is also required which must be shared with the client ahead of time.

#### Set the `--common-name`

The `--common-name` is part of the auto-tls configuration and is used to configure the certificate-authority.

You can use the public IP address of the inlets-server here, or a DNS record.

* Public IP

    ```sh
    --common-name 35.1.25.103
    ```

* DNS A or CNAME record

    ```sh
    --common-name inlets-control-tunnel1.example.com
    ```

    In this example `inlets-control-tunnel1.example.com` will resolve to the public IP of `35.1.25.103`

You need to configure the client to tell it where to route incoming TCP requests and which port to use.

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
  --url wss://space-mini.local:8123/connect \
  --auto-tls=false
```

Note that you must turn off `--auto-tls`, so that the client does not attempt to download the server's generated CA.

#### Want to generate your own TLS certificate for testing?

Make sure that you set the common-name or TLS SAN name to the hostname that the client will use to connect.

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

### Configure the inlets-pro http

The HTTP mode of inlets PRO is suitable for REST / HTTP traffic. Use it when you want to add TLS termination on the exit-server without running a reverse-proxy in the client's network.

It comes with automatic TLS from Let's Encrypt and should take ~ 5 minutes to set up:

Follow a tutorial: [Get a secure HTTPS tunnel with Let's Encrypt](https://inlets.dev/blog/2021/02/11/secure-letsencrypt-tunnel.html)

See also: `inlets-pro http server --help`
See also: `inlets-pro http client --help`

## Working with Kubernetes

You can deploy an inlets-server in one of three ways:

* As a Service type LoadBalancer

    It will gain its own IP address, and you'll pay for one cloud load-balancer per tunnel. This is the easiest option, and has full encryption with auto-TLS and adds 15-20USD / per IP.

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
