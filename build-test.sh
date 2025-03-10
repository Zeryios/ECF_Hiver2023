#!/bin/bash

# Build de l'application Angular
echo "Building the Angular application..."
ng build 

# Exécution des tests unitaires
echo "Running unit tests..."
ng test --watch=false --browsers=ChromeHeadless
