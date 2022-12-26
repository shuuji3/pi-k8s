#!/usr/bin/env bash

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.crds.yaml
helm repo add cert-manager https://charts.jetstack.io
helm install cert-manager cert-manager/cert-manager --version 1.8.0 -n cert-manager
