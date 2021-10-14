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
ark get gh kind kubectl jq yq argocd-autopilot kubescape kubens kubectx k3sup minikube k9s linkerd2
# Following tools could not be installed for unknown reasons...
# x 404 krew
# x 403 terraform vagrant

gh auth login

# Setup the Kubernetes cluster
k3sup install --ssh-key ~/.ssh/id_ed25519 --local
echo 'export KUBECONFIG=/home/ubuntu/kubeconfig' >> ~/.bashrc
. ~/.bashrc
