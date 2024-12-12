ใช่ครับ สามารถอัพเดทแยกเฉพาะ frontend หรือ backend ได้ ผมจะแสดงตัวอย่างวิธีการทำ:

### 1. สำหรับ Frontend Only Update

```bash
#!/bin/bash
# update-frontend.sh

# 1. Build เฉพาะ frontend image ใหม่
docker-compose build frontend

# 2. Update frontend service แบบ zero downtime
docker-compose up -d --no-deps --scale frontend=2 frontend

# 3. Health check เฉพาะ frontend
./scripts/health-check-frontend.sh
```

### 2. สำหรับ Backend Only Update

```bash
#!/bin/bash
# update-backend.sh

# 1. Build เฉพาะ backend image ใหม่
docker-compose build backend

# 2. Update backend service แบบ zero downtime
docker-compose up -d --no-deps --scale backend=2 backend

# 3. Health check เฉพาะ backend
./scripts/health-check-backend.sh
```

### 3. ปรับ GitHub Actions ให้รองรับการ Deploy แยกส่วน

```yaml
name: Selective Deployment

on:
  push:
    paths:
      - 'frontend/**'
      - 'backend/**'

jobs:
  check-changes:
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
      backend: ${{ steps.filter.outputs.backend }}
    steps:
      - uses: actions/checkout@v2
      - uses: dorny/paths-filter@v2
        id: filter
        with:
          filters: |
            frontend:
              - 'frontend/**'
            backend:
              - 'backend/**'

  deploy-frontend:
    needs: check-changes
    if: ${{ needs.check-changes.outputs.frontend == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy Frontend
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/app
            ./scripts/update-frontend.sh

  deploy-backend:
    needs: check-changes
    if: ${{ needs.check-changes.outputs.backend == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy Backend
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/app
            ./scripts/update-backend.sh
```

### 4. Health Check Scripts แยกส่วน

```bash
#!/bin/bash
# health-check-frontend.sh

MAX_ATTEMPTS=30
ATTEMPT=1

echo "Checking frontend health..."

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -s "http://localhost/health/frontend" | grep -q "healthy"; then
        echo "Frontend is healthy"
        exit 0
    fi
    
    echo "Attempt $ATTEMPT: Frontend not healthy yet..."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

echo "Frontend health check failed"
exit 1
```

```bash
#!/bin/bash
# health-check-backend.sh

MAX_ATTEMPTS=30
ATTEMPT=1

echo "Checking backend health..."

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -s "http://localhost/health/backend" | grep -q "healthy"; then
        echo "Backend is healthy"
        exit 0
    fi
    
    echo "Attempt $ATTEMPT: Backend not healthy yet..."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

echo "Backend health check failed"
exit 1
```

### ข้อดีของการแยก Deploy:

1. ลดความเสี่ยงในการ Deploy
2. Deploy ได้เร็วขึ้นเพราะ Build เฉพาะส่วนที่เปลี่ยน
3. ง่ายต่อการ Debug หากมีปัญหา
4. ลดการใช้ทรัพยากรในการ Build และ Deploy

### ข้อควรระวัง:

1. ต้องมั่นใจว่า API Version ระหว่าง Frontend และ Backend ยังคง Compatible กัน
2. ควรมีการทำ API Versioning
3. ควรมีการทำ Documentation ให้ชัดเจนว่าการเปลี่ยนแปลงใดต้องการ Deploy ทั้งสองส่วนพร้อมกัน