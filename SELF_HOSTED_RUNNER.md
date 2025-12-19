# วิธีติดตั้ง GitHub Actions Self-Hosted Runner บน Ubuntu Server

## ทำไมต้องใช้ Self-Hosted Runner?

เนื่องจาก Ubuntu server อยู่ใน **private network** (192.168.x.x) ซึ่ง GitHub Actions ที่รันบน cloud ไม่สามารถเข้าถึงได้

**Self-Hosted Runner** = ติดตั้ง GitHub Actions agent บน Ubuntu server เอง เพื่อให้รัน workflows ได้โดยตรง

---

## ขั้นตอนการติดตั้ง

### 1. ไปที่ GitHub Repository Settings

1. เปิด repository `goodpack-web` หรือ `goodpack-server` บน GitHub
2. ไปที่ **Settings** → **Actions** → **Runners**
3. คลิก **New self-hosted runner**
4. เลือก **Linux** และ **x64**

### 2. ติดตั้ง Runner บน Ubuntu Server

ทำตามคำสั่งที่ GitHub แสดง หรือใช้คำสั่งด้านล่าง (แทนที่ `TOKEN` ด้วย token จาก GitHub):

```bash
# สร้าง folder สำหรับ runner
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure (ใช้ token จาก GitHub)
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# ติดตั้งเป็น service
sudo ./svc.sh install
sudo ./svc.sh start
```

### 3. ตรวจสอบ Runner Status

```bash
# ดู status
sudo ./svc.sh status

# หรือ
systemctl status actions.runner.*.service
```

กลับไปที่ GitHub → Settings → Actions → Runners ควรเห็น runner status เป็น **Idle** (พร้อมใช้งาน)

---

## การใช้งาน

### Auto Deploy เมื่อ Push

หลังจากติดตั้ง runner แล้ว เมื่อ push code ไป master จะ deploy อัตโนมัติ

### Manual Deploy

1. ไปที่ GitHub → Actions → **Deploy (Self-Hosted Runner)**
2. คลิก **Run workflow**
3. เลือก target: `all`, `web`, หรือ `server`
4. คลิก **Run workflow**

---

## Troubleshooting

### Runner offline

```bash
# Restart runner service
sudo ~/actions-runner/svc.sh stop
sudo ~/actions-runner/svc.sh start
```

### ดู logs

```bash
# Runner logs
cat ~/actions-runner/_diag/*.log

# Workflow logs ดูได้บน GitHub → Actions
```

### Permission denied

ให้ runner user มี sudo permission โดยไม่ต้องใส่ password:

```bash
sudo visudo
```

เพิ่มบรรทัด:
```
YOUR_USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx, /bin/rm, /bin/cp
```

---

## โครงสร้าง Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `deploy-self-hosted.yml` | push to master, manual | Deploy ผ่าน self-hosted runner (แนะนำ) |
| `deploy-web.yml` | push flutter_app/** | Deploy web ผ่าน SSH (ต้อง port forward) |
| `deploy-server.yml` | push go_server/** | Deploy server ผ่าน SSH (ต้อง port forward) |
| `deploy-all.yml` | manual | Deploy ทั้งหมดผ่าน SSH |

**แนะนำ**: ใช้ `deploy-self-hosted.yml` สำหรับ private network

