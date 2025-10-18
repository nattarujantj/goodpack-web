# Environment Variables Configuration

## 📋 Overview
This Flutter app uses environment variables to configure URLs and settings instead of hard-coded values.

## 🔧 Environment Variables

### API Configuration
- `API_BASE_URL`: Base URL for API calls (default: `http://localhost:8080/api`)
- `API_HOST`: API hostname (default: `localhost`)
- `API_PORT`: API port (default: `8080`)
- `API_PROTOCOL`: API protocol (default: `http`)

### QR Code Configuration
- `QR_BASE_URL`: Base URL for QR codes (default: `https://goodpack.app`)
- `QR_DOMAIN`: QR domain name (default: `goodpack.app`)

### Development Configuration
- `ENVIRONMENT`: Environment type (default: `development`)
- `DEBUG_MODE`: Debug mode flag (default: `true`)

### Network Configuration
- `WEB_HOST`: Web server host (default: `0.0.0.0`)
- `WEB_PORT`: Web server port (default: `3000`)

### Other Configuration
- `PLACEHOLDER_IMAGE_URL`: Placeholder image URL

## 🚀 Running the App

### Development Mode (Local)
```bash
./run_dev.sh
```
- API: `http://localhost:8080/api`
- Web: `http://localhost:3000`

### Mobile Access Mode
```bash
./run_mobile.sh
```
- API: `http://[LOCAL_IP]:8080/api`
- Web: `http://[LOCAL_IP]:3000`
- Accessible from mobile devices on same WiFi

### Production Mode
```bash
./run_prod.sh
```
- API: `https://api.goodpack.app/api`
- Web: `http://localhost:3000`

## 📱 Mobile Access

### Step 1: Run Mobile Script
```bash
cd goodpack/flutter_app
./run_mobile.sh
```

### Step 2: Find Your IP
The script will display your local IP address:
```
📱 Local IP: 192.168.1.159
📱 Access from mobile: http://192.168.1.159:3000
```

### Step 3: Access from Mobile
1. Connect mobile to same WiFi network
2. Open browser on mobile
3. Navigate to: `http://[YOUR_IP]:3000`

## 🔧 Custom Configuration

### Method 1: Environment Variables
```bash
export API_BASE_URL="http://192.168.1.100:8080/api"
export QR_BASE_URL="https://myapp.com"
flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0
```

### Method 2: Modify Scripts
Edit the `.sh` files to change default values.

## 📁 File Structure
```
lib/config/
├── env_config.dart      # Environment configuration
├── app_config.dart      # App configuration (uses env_config)
└── app_router.dart      # Router configuration

scripts/
├── run_dev.sh          # Development mode
├── run_mobile.sh       # Mobile access mode
└── run_prod.sh         # Production mode
```

## 🐛 Troubleshooting

### Flutter Command Not Found
```bash
# Update FLUTTER_PATH in scripts
FLUTTER_PATH="/path/to/your/flutter/bin/flutter"
```

### Cannot Access from Mobile
1. Check firewall settings
2. Ensure both devices on same WiFi
3. Try different IP address
4. Check if port 3000 is open

### API Connection Issues
1. Verify Go server is running on port 8080
2. Check API_BASE_URL environment variable
3. Ensure CORS is enabled on server

## 🔄 Migration from Hard-coded URLs

### Before (Hard-coded):
```dart
static const String baseUrl = 'http://localhost:8080/api';
String get qrCodeData => 'https://goodpack.app/product/$skuId';
```

### After (Environment Variables):
```dart
static String get baseUrl => EnvConfig.apiUrl;
String get qrCodeData => '${EnvConfig.qrCodeUrl}/$skuId';
```

## 📝 Notes
- Environment variables are set at compile time
- Use `--dart-define` for runtime configuration
- All URLs are now configurable without code changes
- Scripts automatically detect local IP for mobile access
