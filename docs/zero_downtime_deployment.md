ในการ Deploy แบบ Zero Downtime สามารถทำได้โดยปรับ deployment strategy ดังนี้:

### 1. ปรับ Docker Compose ให้รองรับ Zero Downtime

```yaml
version: '3.8'

services:
  frontend:
    deploy:
      replicas: 2
      update_config:
        order: start-first
        failure_action: rollback
        delay: 10s
      rollback_config:
        parallelism: 1
        delay: 10s

  backend:
    deploy:
      replicas: 2
      update_config:
        order: start-first
        failure_action: rollback
        delay: 10s
      rollback_config:
        parallelism: 1
        delay: 10s
```

### 2. ปรับ Nginx Configuration เพื่อรองรับ Load Balancing

```nginx
upstream frontend {
    server frontend_1:3000;
    server frontend_2:3000;
    keepalive 32;
}

upstream backend {
    server backend_1:1337;
    server backend_2:1337;
    keepalive 32;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 3. ปรับ Deployment Script

```bash
#!/bin/bash

# deploy-prod.sh
set -e

# 1. Pull new code
git fetch --tags
git checkout $(git describe --tags --abbrev=0)

# 2. Load environment variables
set -a
source .env.production
set +a

# 3. Build new images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# 4. Update services one by one
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --no-deps --scale frontend=2 frontend
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --no-deps --scale backend=2 backend

# 5. Health check
./scripts/health-check.sh

# 6. Clean up
docker system prune -f
```

### 4. เพิ่ม Health Check Script

```bash
#!/bin/bash
# health-check.sh

check_service() {
    local service=$1
    local max_attempts=30
    local attempt=1

    echo "Checking $service health..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost/health/$service" | grep -q "healthy"; then
            echo "$service is healthy"
            return 0
        fi
        
        echo "Attempt $attempt: $service not healthy yet..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "$service health check failed"
    return 1
}

# Check each service
check_service "frontend" || exit 1
check_service "backend" || exit 1
```

### 5. ปรับ GitHub Actions Workflow

```yaml
name: Production Deployment

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Deploy to Production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.DO_HOST }}
          username: ${{ secrets.DO_USERNAME }}
          key: ${{ secrets.DO_SSH_KEY }}
          script: |
            cd /opt/app
            # Run deployment with rollback capability
            if ! ./scripts/deploy-prod.sh; then
              echo "Deployment failed, rolling back..."
              ./scripts/rollback.sh
              exit 1
            fi
```

### 6. เพิ่ม Rollback Script

```bash
#!/bin/bash
# rollback.sh

# Get previous working version
PREV_VERSION=$(git describe --tags --abbrev=0 HEAD^)

# Checkout previous version
git checkout $PREV_VERSION

# Deploy previous version
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Health check
./scripts/health-check.sh
```

### ข้อดีของการทำ Zero Downtime Deployment:

1. ไม่มีการหยุดให้บริการระหว่าง Deploy
2. รองรับการ Rollback อัตโนมัติ
3. มีการ Health Check เพื่อยืนยันว่าระบบทำงานได้ปกติ
4. Load Balancing ระหว่าง Instances
5. Graceful Shutdown ของ Services เก่า

### ข้อควรระวัง:

1. ต้องการทรัพยากรเพิ่มขึ้นเนื่องจากต้องรัน Multiple Instances
2. ต้องจัดการ Database Migration อย่างระมัดระวัง
3. ต้องออกแบบ Application ให้รองรับ Multiple