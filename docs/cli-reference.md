# inlets-pro CLI reference

There are two components to inlets-pro, the server and the client.

This reference guide is designed for self-service, but customers of OpenFaaS Ltd can request hands-on support and training. Just email sales@openfaas.com for more.

## Contents:

* Working with MacOS, Linux, and Windows
* Configure the inlets-pro client
* Configure the inlets-pro server
* Troubleshooting
* Working with Kubernetes

## Working with MacOS, Linux, and Windows

The examples given in the documentation are valid for all three operating systems and use bash as a syntax.

Windows users can use either Windows Subsystem for Linux (WSL) or [Git bash](https://git-scm.com/downloads), this is the simplest way to make all commands compatible.

The client and server component are packaged in the same `inlets-pro` binary and can be run as:

* A process on MacOS, Linux, Windows on ARM or Intel architecture
* As a Docker container with docker, or Kubernetes as a Pod on ARM or Intel architecture

### Configure the inlets-pro client

The client component connects to an inlets server and then routes incoming requests to a private service. The client can run on the same host as your private service, or run on another host and act as gateway.

#### Set the license

The license terms of inlets-pro require that both the inlets client and server have a valid license, only the client requires to have the license configured.

You can configure the license in one of two ways:

* From a file `--license-file`

    ```sh
    # Assume a file of `pro-license.txt` with the license key, no new lines or whitespace
    inlets-pro client \
    --license-file=pro-license.txt
    ```

* literal flag `--license`

    ```sh
    inlets-pro client \
    --license="LICENSE_KEY_VALUE"
    ```

* literal flag with environment variable

    ```sh
    export INLETS_LICENSE="LICENSE_KEY_VALUE"
    inlets-pro client \
    --license="$INLETS_LICENSE"
    ```

* literal flag with environment variable set in your bash profile

    You can also set the INLETS_LICENSE file for each terminal session by editing `$HOME/.bash_profile`

    Add a line for:

    ```sh
    export INLETS_LICENSE="LICENSE_KEY_VALUE"
    ```

### Set the TCP ports for the tunnel `--tcp-ports`

The client will advertise which TCP ports it requires the server to open, this is done via the `--tcp-ports` flag

* A single alternative HTTP port

    `--tcp-ports=8080`

* Nginx, or a HTTP service with TLS

    `--tcp-ports=80,443`

### Connect to the remote host (server) with `--connect`

inlets-pro uses a websocket for its control plane on port `8123` by default and adds automatic TLS. This is an optional feature.

* Automatic TLS with `auto tls`

    In this mode the client and server will negotiate TLS through the use of a generate Certificate Authority (CA) and encrypt all traffic automatically.

    This is the default option, connect with `wss://` and the IP of the remote machine

    `--connect wss://remote-machine:8123/connect`

    The control-port of 8123 is used for auto-tls.

* External TLS

    In this mode, you are providing your own TLS certificate or termination through a gateway, IngressController, reverse-proxy or some other kind of product.

    Turn auto-TLS off, and use port 443 (implicit) for the control-plane.

    `--connect wss://remote-machine/connect`

    You must also pass the `--auto-tls=false` flag

* No TLS or encryption

    This mode may be useful for testing, but is not recommended for confidential use.

    `--connect ws://remote-machine:8123/connect`

    Use port `8123` for the control-plane and `ws://` instead of `wss://`

#### Set the authentication token `--token`

The inlets-pro server requires a token for authentication to make sure that the client is genuine. It is recommended to combine the use of the token with auto-tls or external TLS.

You can create your own token, or generate one with bash:

```sh
export TOKEN="$(head -c 16 /dev/urandom |shasum|cut -d'-' -f1)"
echo $TOKEN
```

Now pass the token via `--token $TOKEN`.

### Generate a systemd unit file for the client

Add "inlets-pro client --generate=systemd" to generate a system unit file for your client along with all the other required parameters.

For example:

```bash
export TOKEN="auth token"
inlets-pro client --generate=systemd \
  --license-file /var/lib/inlets-pro/LICENSE \
  --tcp-ports "80,443" \
  --connect "wss://167.99.90.104:8123/connect" \
  --token $TOKEN
```

### Configure the inlets-pro server

The inlets-pro server begins by opening a single TCP port for the control-plane, this is port `8123`, but you can customise it if required.

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

. You need to configure the client to tell it where to route incoming TCP requests and which port to use.

#### Set the remote TCP address `--remote-tcp`

The server needs to be configured with a "remote TCP address" which corresponds to where to direct incoming traffic to. Unlike the `--tcp-ports` which is set on the client, this value is set at the server.

* For a client running on your local computer or a VM

    Set `--remote-tcp` - set to `127.0.0.1` for the local machine

* For a client acting as a gateway, specify the hostname or IP address as seen by the client

    Set `--remote-tcp` - set to `192.168.0.1` if the host running your private service is `192.168.0.1` on the local network

* For a Kubernetes Pod

    Set `--remote-tcp` - set to the name of the destination Kubernetes service such as a ClusterIP `nginx.default`

#### Set the authentication token `--token`

The inlets-pro server requires a token for authentication to make sure that the client is genuine. It is recommended to combine the use of the token with auto-tls or external TLS.

You can create your own token, or generate one with bash:

```sh
export TOKEN="$(head -c 16 /dev/urandom |shasum|cut -d'-' -f1)"
echo $TOKEN
```

Now pass the token via `--token $TOKEN`.

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

    This configuration is ideal for command and control. The private network will be able to traverse firewalls and NAT to connect to the remote inlets-pro server, but only internal services within the Kubernetes cluster can connect to the tunnelled service.

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
