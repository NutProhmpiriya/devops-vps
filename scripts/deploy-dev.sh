#!/bin/bash
set -e

# Pull the latest changes
git pull origin main

# Load environment variables
set -a
source .env.development
set +a

# Build and deploy using docker-compose
docker-compose -f infra/docker/docker-compose.dev.yml pull
docker-compose -f infra/docker/docker-compose.dev.yml up -d --build

# Clean up old images
docker image prune -f
