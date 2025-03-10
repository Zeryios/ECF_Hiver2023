#!/bin/bash

# --- Configuration ---
DEPLOYMENT_NAME="my-app-deployment"       # Nom du déploiement Kubernetes
NAMESPACE="default"                       # Namespace Kubernetes
DOCKER_IMAGE="zeryios272/hello-node-v2:latest"  # Nom complet de l'image Docker
K8S_MANIFEST_FILE="k8s-deployment.yaml"   # Fichier Kubernetes contenant les manifests

# --- Étape 1 : Appliquer les manifests Kubernetes ---
echo "Applying Kubernetes manifests..."
kubectl apply -f $K8S_MANIFEST_FILE --namespace=$NAMESPACE
if [ $? -ne 0 ]; then
  echo "Failed to apply Kubernetes manifests."
  exit 1
fi

# --- Étape 2 : Mettre à jour l'image Docker du déploiement ---
echo "Updating Kubernetes deployment image..."
kubectl set image deployment/$DEPLOYMENT_NAME \
  hello-node-v2=$DOCKER_IMAGE --namespace=$NAMESPACE
if [ $? -ne 0 ]; then
  echo "Failed to update deployment image."
  exit 1
fi

# --- Étape 3 : Vérifier le statut du déploiement ---
echo "Checking deployment rollout status..."
kubectl rollout status deployment/$DEPLOYMENT_NAME --namespace=$NAMESPACE
if [ $? -ne 0 ]; then
  echo "Deployment failed."
  exit 1
fi

echo "Deployment completed successfully!"
