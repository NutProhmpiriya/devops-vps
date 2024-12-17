หากต้องการใช้ **SSH Tunnel** สำหรับเชื่อมต่อฐานข้อมูลจาก **Docker Compose** ไปยัง VPS อย่างปลอดภัย สามารถทำตามขั้นตอนนี้ได้ครับ:

---

## **1. ทำความเข้าใจ SSH Tunnel**
**SSH Tunnel** ทำให้คุณสามารถสร้าง **port forwarding** ผ่าน SSH เพื่อให้ Docker Container เชื่อมต่อฐานข้อมูลได้เหมือนกับว่าอยู่ในเครื่อง local.

ตัวอย่าง:
- Local port `5432` เชื่อมต่อกับ Remote PostgreSQL Port `5432` บน VPS ผ่าน SSH.

---

## **2. สร้าง SSH Tunnel บนเครื่อง Local**
รันคำสั่งนี้เพื่อสร้าง SSH Tunnel:
```bash
ssh -L 5432:<DATABASE_HOST>:5432 <SSH_USER>@<VPS_IP>
```

- **5432**: พอร์ต PostgreSQL บนเครื่อง Local.
- **<DATABASE_HOST>**: `localhost` หรือ IP ภายใน VPS.
- **<VPS_IP>**: IP Address ของ VPS.
- **<SSH_USER>**: ผู้ใช้ SSH (เช่น `root` หรือ `ubuntu`).

หลังจากรันคำสั่งนี้:
- พอร์ต `5432` บนเครื่อง Local จะเชื่อมต่อกับ PostgreSQL บน VPS ผ่าน SSH.

---

## **3. ตั้งค่า Docker Compose ให้ใช้ SSH Tunnel**
ในไฟล์ **docker-compose.yml** ให้ชี้ `DATABASE_HOST` เป็น **localhost** (เพราะ SSH Tunnel ทำการ forward พอร์ตไว้แล้ว):

### **ตัวอย่างไฟล์ `docker-compose.yml`**
```yaml
version: '3'
services:
  app:
    image: my-app:dev
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: localhost     # ใช้ SSH Tunnel
      DATABASE_PORT: 5432          # พอร์ต SSH Tunnel
      DATABASE_NAME: my_database
      DATABASE_USERNAME: my_user
      DATABASE_PASSWORD: my_password
    ports:
      - "3000:3000"
```

---

## **4. ตรวจสอบการเชื่อมต่อผ่าน Docker**
1. รัน SSH Tunnel:
   ```bash
   ssh -L 5432:localhost:5432 root@<VPS_IP>
   ```

2. รัน Docker Compose:
   ```bash
   docker-compose up
   ```

3. ทดสอบการเชื่อมต่อ:
   - เข้าไปใน Container:
     ```bash
     docker exec -it <container_name> /bin/sh
     ```
   - เช็คการเชื่อมต่อกับ PostgreSQL:
     ```bash
     psql -h localhost -U my_user -d my_database
     ```

---

## **5. ทำให้ SSH Tunnel ทำงานอยู่ตลอด**
หากไม่ต้องการรัน SSH Tunnel ทุกครั้ง สามารถใช้ `autossh` เพื่อเปิด Tunnel ตลอดเวลา:

### ติดตั้ง autossh:
```bash
sudo apt install autossh
```

### สร้าง SSH Tunnel แบบคงที่:
```bash
autossh -f -N -L 5432:localhost:5432 root@<VPS_IP>
```
- **`-f`**: รันใน background.
- **`-N`**: ไม่รันคำสั่งบน SSH, แค่ทำ Tunnel.

---

## **6. สรุปขั้นตอน**
1. เปิด SSH Tunnel ด้วย:
   ```bash
   ssh -L 5432:localhost:5432 root@<VPS_IP>
   ```
2. ตั้งค่า `DATABASE_HOST` ใน **docker-compose.yml** เป็น `localhost`.
3. รัน Docker Compose ปกติ.
4. ใช้ `autossh` เพื่อทำให้ SSH Tunnel คงอยู่ตลอดเวลา.

