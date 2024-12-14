#!/bin/bash
set -e

# Pull the latest changes
git fetch --tags
git checkout $TAG

# Load environment variables
set -a
source .env.production
set +a

# Build and deploy using docker-compose
docker-compose -f infra/docker/docker-compose.prod.yml pull
docker-compose -f infra/docker/docker-compose.prod.yml up -d --build

# Clean up old images
docker image prune -f
