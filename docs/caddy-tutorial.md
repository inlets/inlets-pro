# Tutorial

Run Caddy on your local machine and obtain TLS certificates served from your computer, as if it had a real, public IP. 

Scenario: You want to share a file such as a VM image or a ISO over the Internet, with HTTPS, directly from your laptop.

## Setup your exit node

Provision a VM on DigitalOcean or another IaaS provider.

Log in with ssh and obtain the binary:

```sh
curl -SLsf https://github.com/inlets/inlets-pro/releases/download/0.6.0/inlets-pro > inlets-pro
chmod +x ./inlets-pro
mv ./inlets-pro /usr/bin/inlets-pro
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

## Setup your DNS A record

Setup a DNS A record for the site you want to expose using the public IP of the exit node

* `178.128.40.109` = `share.example.com`

## Setup Caddy 1

* Download the latest Caddy binary from the [Releases page](https://github.com/caddyserver/caddy/releases) - on a VPS you want a binary with a name like caddy_v0.11.5_linux_amd64.tar.gz. (you can use `wget https://` to download the file.)
* Uncompress the tar.gz file: tar -xvf caddy_v0.11.5_linux_amd64.tar.gz

* Create a Caddyfile replacing share.domain.com with your own DNS record:

```sh
share.domain.com

proxy / 127.0.0.1:8000 {
  transparent
}
```

Start the Caddy binary, it will listen on port 80 and 443.

## Run a local server to share files

```
mkdir -p /tmp/shared/
cd /tmp/shared/

echo "Hello world" > WELCOME.txt

# If Python version is 3.x
python3 -m http.server

# Or use this for 2.x
python -m SimpleHTTPServer
```

## Start the inlets-pro client on your local side

For a Linux client

```sh
curl -SLsf https://github.com/inlets/inlets-pro/releases/download/0.6.0/inlets-pro > inlets-pro
chmod +x ./inlets-pro
mv ./inlets-pro /usr/bin/inlets-pro
```

For a MacOS client

```sh
curl -SLsf https://github.com/inlets/inlets-pro/releases/download/0.6.0/inlets-pro > inlets-pro
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
  --tcp-ports 80,443 \
  --token $TOKEN \
  --license $LICENSE
```

## Check it all worked

Now visit `https://share.example.com`

Congratulations, you've now served a TLS certificate directly from your laptop. You can close caddy and open it again at a later date. Caddy will re-use the certificate it already obtained and it will be valid for 3 months. To renew, just keep Caddy running or open it again whenever you need it.
