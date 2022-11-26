#!/usr/bin/env bash

# Temporary note required to setup the cluster

ssh-import-id gh:shuuji3
ssh-keygen -t ed25519

sudo hostnamectl set-hostname pi-0

# Setup docker
sudo snap install docker
sudo addgroup docker
sudo adduser ubuntu docker
sudo usermod -aG docker ubuntu
sudo chown root:docker /var/run/docker.sock
sudo chown -R root:docker /var/run/docker

# Install arkade
curl -sLS https://get.arkade.dev | sudo sh
echo 'export PATH=$PATH:$HOME/.arkade/bin/' >> ~/.bashrc
. ~/.bashrc

# Install
ark get gh kind kubectl jq yq argocd-autopilot kubescape kubens kubectx k3sup minikube k9s linkerd2 faas-cli
# Following tools could not be installed for unknown reasons...
# x 404 krew
# x 403 terraform vagrant

gh auth login

# Setup the Kubernetes cluster
k3sup install --ssh-key ~/.ssh/id_ed25519 --local
echo 'export KUBECONFIG=/home/ubuntu/kubeconfig' >> ~/.bashrc
. ~/.bashrc

# Setup Prometheus
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus/
kubectl create -f manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f manifests/

# Get certificate for TLS tunnel
sudo apt install certbot
sudo certbot certonly -m shuuji3@gmail.com -d pi-k8s.shuuji3.xyz --standalone --test-cert --agree-tos
sudo certbot certonly -m shuuji3@gmail.com -d home.shuuji3.xyz --standalone --test-cert --agree-tos

# Run on pi
ubuntu@pi-0:~/ghostunnel$
sudo apt install make
sudo snap install go
make ghostunnel
sudo ./ghostunnel server --allow-all --cacert certs/pi-k8s-shuuji3-xyz.pem --cert certs/home-shuuji3-xyz.pem --key certs/home-shuuji3-xyz-key.pem --listen 0.0.0.0:3000 --target localhost:4000
[2838603] 2021/11/07 15:30:52.294959 starting ghostunnel in server mode
[2838603] 2021/11/07 15:30:52.296001 using cert/key files on disk as certificate source
[2838603] 2021/11/07 15:30:52.298881 using target address localhost:4000
[2838603] 2021/11/07 15:30:52.299174 listening for connections on 0.0.0.0:3000

# Run on pi-k8s on GCP
shuuji3@pi-k8s-inlets:~$
sudo ./ghostunnel client --cacert certs/home-shuuji3-xyz.pem --key certs/pi-k8s-shuuji3-xyz-key.pem --cert certs/pi-k8s-shuuji3-xyz.pem --target home.shuuji3.xyz:55540 --listen 0.0.0.0:8000 --unsafe-listen
[15860] 2021/11/07 15:30:49.946349 starting ghostunnel in client mode
[15860] 2021/11/07 15:30:49.999566 using target address home.shuuji3.xyz:55540
[15860] 2021/11/07 15:30:49.999866 listening for connections on 0.0.0.0:8000

# setup caddy
# /etc/caddy/Caddyfile
pi-k8s.shuuji3.xyz {
        reverse_proxy localhost:8000
}

# Finally I can create end to end TLS tunnel
The Internet
-> https://pi-k8s.shuuji3.xyz
-> GCP instance
-> Caddy (TLS + Let's Encript Certificate) reverse-proxy
   in :443
   out :8000
-> ghostunnel client: TLS tunnel with self-signed server & client certificate
   in :8000
   out home.shuuji3.xyz:55540 (limitation of the IPv6 Plus on FLETS network)
-> router port forwarding feature
   in: home.shuuji3.xyz:55540
   out: pi-0.local:3000
-> ghostunnel server
   in: :3000
   out :4000
-> `go run main.go` HTTP server at :4000
