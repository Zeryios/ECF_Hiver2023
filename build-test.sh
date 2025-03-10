#!/bin/bash

# Variables
IMAGE_NAME="hello-node-v2"
IMAGE_TAG="latest"
DOCKER_REGISTRY="zeryios272"  # Changez si nécessaire (ex : Docker Hub ou autre registre)
EXIT_CODE=0

# 1. Installer les dépendances
echo "Installing Node.js dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "Error: Failed to install dependencies."
    exit 1
fi

# 2. Lancer les tests
echo "Running tests..."
npm test
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "Error: Tests failed. Aborting build."
    exit $EXIT_CODE
fi

# 3. Construire l'image Docker
echo "Building Docker image..."
docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG .
if [ $? -ne 0 ]; then
    echo "Error: Failed to build Docker image."
    exit 1
fi

echo "Build and test completed successfully!"
exit 0
