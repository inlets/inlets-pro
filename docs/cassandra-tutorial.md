# Tutorial

TCP tunnel for Apache Cassandra running on your local machine, out to another network

Scenario: You're running Apache Cassandra, which uses TCP and which cannot be forwarded easily by Ngrok or Inlets OSS. Inlets Pro provides a solution for you.

## Setup your exit node

Provision a VM on DigitalOcean or another IaaS provider.

Log in with ssh and obtain the binary:

```sh
curl -SLsf https://github.com/inlets/inlets-pro-pkg/releases/download/0.4.2/inlets-pro-linux > inlets-pro-linux
chmod +x ./inlets-pro-linux
mv ./inlets-pro-linux /usr/bin/inlets-pro
```

Find your public IP:

```
export IP=$(curl -s ifconfig.co)
```

Confirm the IP with `echo $IP` and save it, you need it for the client

Get an auth token and save it for later to use with the client

```sh
export TOKEN="$(head -c 16 /dev/urandom |shasum|cut -d'-' -f1)"

echo $TOKEN
```

Start the server:

```sh
sudo inlets-pro server \
  --auto-tls \
  --common-name $IP \
  --remote-tcp 127.0.0.1 \
  --token $TOKEN
```

## Get Cassandra on your laptop

Using Docker you can run Cassandra.

```sh
docker run --name cassandra  -p 9042:9042 -ti cassandra:latest
```

The client port is `9042` which will become available on the public IP

Now run the inlets client on the other side:

For a Linux client

```sh
curl -SLsf https://github.com/inlets/inlets-pro-pkg/releases/download/0.4.2/inlets-pro-linux > inlets-pro-linux
chmod +x ./inlets-pro-linux
mv ./inlets-pro-linux /usr/bin/inlets-pro
```

For a MacOS client

```sh
curl -SLsf https://github.com/inlets/inlets-pro-pkg/releases/download/0.4.2/inlets-pro > inlets-pro
chmod +x ./inlets-pro
sudo mv ./inlets-pro /usr/bin/inlets-pro
```

Run the inlets-pro client:

```sh
export IP=""        # take this from the exit node
export TOKEN=""     # take this from the server earlier
export LICENSE=""   # your license

sudo -E inlets-pro client \
  --connect wss://$IP:8123/connect \
  --tcp-ports 9042 \
  --token $TOKEN \
  --license $LICENSE
```

## Connect to Cassandra on your exit node

On your laptop or another computer use the Cassandra client `cqlsh` to connect and verify the tunnel is operational.

```sh
export IP=""    # Exit-node IP
docker run \
  -e CQLSH_HOST=$IP \
  -e CQLSH_PORT=9042 \
  -it --rm cassandra cqlsh
```

Now you're connected.

```sh
Connected to Test Cluster at 185.136.232.127:9042.
[cqlsh 5.0.1 | Cassandra 3.11.4 | CQL spec 3.4.4 | Native protocol v4]
Use HELP for help.
cqlsh> 
```

Try a query:

```sh
cqlsh> SELECT cluster_name, listen_address FROM system.local;

 cluster_name | listen_address
--------------+----------------
 Test Cluster |     172.17.0.2

(1 rows)
cqlsh> 
```

