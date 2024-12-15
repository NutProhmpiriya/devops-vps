# VPS Deployment Automation

This repository contains the infrastructure and deployment automation for a full-stack application deployed on DigitalOcean VPS.

## Architecture

- Frontend: Next.js
- Backend: Strapi
- Database: PostgreSQL
- Cache: Redis
- Reverse Proxy: Nginx

## Environments

- Development: Automatically deployed on push to main branch
- Production: Deployed on new release tags

## Prerequisites

- Docker and Docker Compose
- GitHub account
- DigitalOcean account
- Domain name (for production)

## Directory Structure

```
.
├── infra/
│   ├── docker/
│   │   ├── docker-compose.dev.yml
│   │   └── docker-compose.prod.yml
│   ├── nginx/
│   │   ├── dev.conf
│   │   └── prod.conf
│   └── scripts/
│       ├── deploy-dev.sh
│       └── deploy-prod.sh
├── .github/
│   └── workflows/
│       ├── dev-deploy.yml
│       └── prod-deploy.yml
└── README.md
```

# Development
docker-compose -f docker-compose.dev.yml --env-file .env.development up

# Production
docker-compose -f docker-compose.prod.yml --env-file .env.production up