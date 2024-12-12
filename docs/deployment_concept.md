# แผนการทำ Auto Deployment

## 1. โครงสร้างโปรเจค
```
project/
├── frontend/
│   ├── Dockerfile
│   └── .env.development
├── backend/
│   ├── Dockerfile
│   └── .env.development
├── docker-compose.yml
├── .github/workflows/
│   └── deploy.yml
└── scripts/
    └── deploy.sh
```

## 2. Docker Configuration

### docker-compose.yml
```yaml
version: '3'
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    env_file: ./frontend/.env.development

  backend:
    build: ./backend
    ports:
      - "1337:1337"
    env_file: ./backend/.env.development
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:latest
    environment:
      POSTGRES_DB: strapi
      POSTGRES_USER: strapi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:latest
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## 3. GitHub Actions Workflow

### .github/workflows/deploy.yml
```yaml
name: Deploy to Digital Ocean

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install SSH key
        uses: shimataro/ssh-key-action@v2
        with:
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          known_hosts: ${{ secrets.KNOWN_HOSTS }}

      - name: Deploy to Digital Ocean
        env:
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
          DO_HOST: ${{ secrets.DO_HOST }}
        run: |
          chmod +x ./scripts/deploy.sh
          ./scripts/deploy.sh
```

## 4. Deployment Script

### scripts/deploy.sh
```bash
#!/bin/bash

# Login to Docker Hub
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Build and push images
docker-compose build
docker-compose push

# Deploy to Digital Ocean
ssh root@$DO_HOST << 'ENDSSH'
cd /root/project
docker-compose pull
docker-compose down
docker-compose up -d
ENDSSH
```

## 5. Digital Ocean Setup

1. สร้าง Droplet
```bash
- Size: Basic Plan (4GB/2CPU)
- Region: Singapore
- OS: Ubuntu 20.04
```

2. ติดตั้ง Dependencies
```bash
apt update
apt install -y docker.io docker-compose
```

## 6. Security & Environment Variables

### GitHub Secrets ที่ต้องตั้งค่า
```
SSH_PRIVATE_KEY
KNOWN_HOSTS
DOCKER_USERNAME
DOCKER_PASSWORD
DO_HOST
```

### Environment Variables ที่ต้องกำหนด
```
# Frontend (.env.development)
NEXT_PUBLIC_API_URL=
NEXT_PUBLIC_SITE_URL=

# Backend (.env.development)
DATABASE_URL=
REDIS_URL=
JWT_SECRET=
```

## 7. การ Monitor และ Logging

1. ติดตั้ง Monitoring Tools
```bash
# Prometheus + Grafana หรือ
# Datadog
```

2. Log Management
```bash
# ELK Stack หรือ
# Papertrail
```

## 8. Backup Strategy

1. Database Backup
```bash
# สร้าง Cron job สำหรับ backup Postgres
0 0 * * * pg_dump -U strapi > backup.sql
```

2. Volume Backup
```bash
# Backup Docker volumes
0 0 * * * tar -czf backup.tar.gz /var/lib/docker/volumes
```

## 9. ขั้นตอนการทดสอบ

1. ทดสอบ Local
```bash
docker-compose up --build
```

2. ทดสอบ CI/CD
```bash
- Push to feature branch
- Create PR
- Merge to main
```

## 10. การ Rollback

1. สร้าง rollback script
```bash
./scripts/rollback.sh <version>
```

2. เก็บ Image Tags
```bash
docker tag app:latest app:v1.0.0
```

## คำแนะนำเพิ่มเติม

1. **Security**
- ใช้ HTTPS
- ตั้งค่า Firewall
- Regular Security Updates

2. **Performance**
- ใช้ Docker Layer Caching
- Optimize Docker Images
- CDN สำหรับ Frontend

3. **Monitoring**
- Set up Health Checks
- Alert System
- Performance Monitoring

4. **Documentation**
- Deployment Process
- Troubleshooting Guide
- Architecture Diagram