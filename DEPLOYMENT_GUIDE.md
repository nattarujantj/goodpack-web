# Goodpack Deployment Guide

## Overview

โปรเจคนี้ประกอบด้วย 2 ส่วน:
- **Flutter Web** (Frontend) - อยู่ใน `flutter_app/` หรือ repo `goodpack-web`
- **Go Server** (Backend API) - อยู่ใน `go_server/` หรือ repo `goodpack-server`

---

## 🖥️ Development (Mac)

### รัน Local ทั้ง Frontend และ Backend

```bash
# Terminal 1: รัน Go Server
cd go_server
go run main.go

# Terminal 2: รัน Flutter Web
cd flutter_app
flutter run -d chrome
```

### รัน Local Frontend + Remote API (Ubuntu Server)

ใช้เมื่อต้องการ develop Flutter บน Mac แต่ใช้ API จาก Ubuntu server:

```bash
cd flutter_app
./run_local_with_remote_api.sh

# หรือระบุ API URL เอง
./run_local_with_remote_api.sh http://192.168.1.162:8080/api
```

---

## 🚀 Production (Ubuntu Server)

### First Time Setup

#### 1. Clone repositories

```bash
cd /opt
sudo mkdir -p goodpack-web goodpack-server
sudo chown $USER:$USER goodpack-web goodpack-server

git clone https://github.com/nattarujantj/goodpack-web.git
git clone https://github.com/nattarujantj/goodpack-server.git
```

#### 2. Install dependencies

```bash
# MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Nginx
sudo apt install -y nginx
```

#### 3. Build and Deploy

```bash
# Go Server
cd /opt/goodpack-server
go mod tidy
go build -o server
nohup ./server > server.log 2>&1 &

# Flutter Web
cd /opt/goodpack-web
flutter pub get
flutter build web --dart-define=API_BASE_URL="http://192.168.1.162:8080/api"
sudo cp -r build/web/* /var/www/html/
sudo systemctl restart nginx
```

#### 4. Open Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 8080/tcp
```

---

## 🔄 Auto Deployment with GitHub Actions

### Setup (One Time)

#### 1. Generate SSH Key on Ubuntu Server

```bash
ssh-keygen -t ed25519 -C "github-actions-deploy"
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/id_ed25519  # Copy this private key
```

#### 2. Add GitHub Secrets

ไปที่ GitHub repository → Settings → Secrets and variables → Actions

เพิ่ม secrets ดังนี้:

| Secret Name | Value |
|-------------|-------|
| `SERVER_HOST` | `192.168.1.162` (IP ของ Ubuntu server) |
| `SERVER_USERNAME` | `pukkyntj` (username บน Ubuntu) |
| `SERVER_SSH_KEY` | Private key จากขั้นตอนที่ 1 |

#### 3. ⚠️ Important: Port Forwarding

เนื่องจาก GitHub Actions รันบน cloud ไม่สามารถเข้าถึง private IP ได้โดยตรง ต้องทำอย่างใดอย่างหนึ่ง:

**Option A: Port Forwarding ที่ Router**
- เปิด port 22 (SSH) ที่ router ให้ชี้มา Ubuntu server
- ใช้ Public IP ของบ้าน/ออฟฟิศ

**Option B: ใช้ Cloudflare Tunnel หรือ ngrok**
- ติดตั้ง cloudflared หรือ ngrok บน Ubuntu
- สร้าง tunnel สำหรับ SSH

**Option C: ใช้ Self-Hosted Runner (แนะนำสำหรับ private network)**
- ติดตั้ง GitHub Actions Runner บน Ubuntu server
- ดูรายละเอียดที่ `SELF_HOSTED_RUNNER.md`

---

## 📜 Available Scripts

### Flutter App Scripts

| Script | Description |
|--------|-------------|
| `run_dev.sh` | รัน development mode บน Mac |
| `run_local_with_remote_api.sh` | รัน Flutter + ใช้ API จาก Ubuntu server |
| `build_web.sh` | Build web พร้อมระบุ API URL |
| `deploy.sh` | Build และสร้าง zip สำหรับ deploy |

### Server Scripts

| Script | Description |
|--------|-------------|
| `scripts/deploy_server.sh` | Interactive deploy script (รันบน Ubuntu) |
| `scripts/auto_deploy.sh` | Auto deploy script (ใช้กับ GitHub Actions) |

---

## 🌐 URLs

| Service | URL |
|---------|-----|
| Web App | http://192.168.1.162 |
| API Health | http://192.168.1.162:8080/api/health |

---

## 🔧 Troubleshooting

### Go Server ไม่ start

```bash
# ดู log
tail -f /opt/goodpack-server/server.log

# ตรวจสอบ MongoDB
sudo systemctl status mongod
```

### Flutter Web build failed

```bash
# Clean และ build ใหม่
cd /opt/goodpack-web
flutter clean
flutter pub get
flutter build web --dart-define=API_BASE_URL="http://192.168.1.162:8080/api"
```

### ไม่สามารถเข้าเว็บได้จากเครื่องอื่น

1. ตรวจสอบ Firewall: `sudo ufw status`
2. ตรวจสอบ nginx: `sudo systemctl status nginx`
3. ตรวจสอบว่าอยู่ในเครือข่ายเดียวกัน

