#!/usr/bin/bash

source ../.env
echo "DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
# Pull the latest Docker image for the frontend
docker pull $DOCKERHUB_USERNAME/frontend:latest

# Run the Docker image for the frontend
docker run -d --name frontend-container $DOCKERHUB_USERNAME/frontend:latest
