#!/bin/bash

# Create namespace for application
kubectl create namespace driving-navigation

# Create cert and key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=driving-navigation-service"

# Create secret for cert and key
kubectl create secret tls driving-navigation-tls --key="tls.key" --cert="tls.crt" -n driving-navigation

# Deploy applications
kubectl apply -f ./driving-navigation-yamls