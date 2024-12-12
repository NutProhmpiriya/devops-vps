# การเข้าถึง Services ต่างๆ

## 1. Frontend (Next.js)
```yaml
# ภายใน Network
URL: http://frontend:3000
# ภายนอก Network
URL: http://your-domain.com หรือ http://server-ip:3000
```

### การเชื่อมต่อจาก Browser
```javascript
// ตัวอย่างการเรียก API
fetch('http://your-domain.com/api/...')
```

## 2. Backend (Strapi)
```yaml
# ภายใน Network
URL: http://backend:1337
# ภายนอก Network
URL: http://your-domain.com/api หรือ http://server-ip:1337
```

### การเชื่อมต่อจาก Frontend
```javascript
// ใน .env.development ของ Frontend
NEXT_PUBLIC_API_URL=http://backend:1337

// การใช้งานใน Next.js
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/posts`)
```

## 3. PostgreSQL
```yaml
# Connection Info
Host: postgres
Port: 5432
Database: strapi
Username: strapi
Password: ${DB_PASSWORD}
```

### การเชื่อมต่อจาก Backend (Strapi)
```javascript
// ใน .env.development ของ Backend
DATABASE_URL=postgres://strapi:${DB_PASSWORD}@postgres:5432/strapi

// หรือแบบแยก
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=${DB_PASSWORD}
```

### การเชื่อมต่อโดยตรง
```bash
# เข้าถึง PostgreSQL CLI
docker exec -it postgres psql -U strapi -d strapi

# Backup Database
docker exec postgres pg_dump -U strapi > backup.sql

# Restore Database
cat backup.sql | docker exec -i postgres psql -U strapi
```

## 4. Redis
```yaml
# Connection Info
Host: redis
Port: 6379
```

### การเชื่อมต่อจาก Backend
```javascript
// ใน .env.development ของ Backend
REDIS_URL=redis://redis:6379

// การใช้งานใน Code
const Redis = require('ioredis');
const redis = new Redis(process.env.REDIS_URL);
```

### การเชื่อมต่อโดยตรง
```bash
# เข้าถึง Redis CLI
docker exec -it redis redis-cli

# ทดสอบการทำงาน
redis-cli ping
```

## 5. Network Configuration ใน docker-compose.yml

```yaml
version: '3'
services:
  frontend:
    networks:
      - app-network
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:1337

  backend:
    networks:
      - app-network
    environment:
      - DATABASE_URL=postgres://strapi:${DB_PASSWORD}@postgres:5432/strapi
      - REDIS_URL=redis://redis:6379

  postgres:
    networks:
      - app-network
    ports:
      - "5432:5432"  # ถ้าต้องการเข้าถึงจากภายนอก

  redis:
    networks:
      - app-network
    ports:
      - "6379:6379"  # ถ้าต้องการเข้าถึงจากภายนอก

networks:
  app-network:
    driver: bridge
```

## 6. Security Considerations

### การจำกัดการเข้าถึง
```nginx
# Nginx Configuration
location /api {
    proxy_pass http://backend:1337;
}

location /pgadmin {
    proxy_pass http://pgadmin:80;
    # จำกัด IP
    allow 192.168.1.0/24;
    deny all;
}
```

### Firewall Rules
```bash
# ตัวอย่าง UFW Rules
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from trusted-ip to any port 5432  # PostgreSQL
ufw allow from trusted-ip to any port 6379  # Redis
```

## 7. Monitoring Access

### Health Check URLs
```yaml
# Frontend
http://your-domain.com/health

# Backend
http://your-domain.com/api/_health

# Database
pg_isready -h postgres -p 5432

# Redis
redis-cli ping
```

### Logging
```bash
# ดู Logs
docker-compose logs frontend
docker-compose logs backend
docker-compose logs postgres
docker-compose logs redis

# Real-time Logs
docker-compose logs -f service-name
```

## 8. Development Tools

### pgAdmin (PostgreSQL Management)
```yaml
# docker-compose.yml
pgadmin:
  image: dpage/pgadmin4
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@example.com
    PGADMIN_DEFAULT_PASSWORD: admin
  ports:
    - "5050:80"
```

### Redis Commander (Redis Management)
```yaml
# docker-compose.yml
redis-commander:
  image: rediscommander/redis-commander
  environment:
    - REDIS_HOSTS=redis
  ports:
    - "8081:8081"
```