# Stateless Broker Proxy Backend (Node.js)

A high-performance, stateless reverse proxy and bridge server designed for the Flutter Risk Management App.

## 🎯 Purpose
Groww and other trading APIs enforce **IP Whitelisting (Error GA005)**. Since mobile devices and home connections use dynamic IP addresses, direct requests get blocked by Groww.

This backend serves as a **Stateless Bridge** hosted on a VPS with a **Static IP**:
- Flutter sends broker API calls to this Node.js proxy server.
- The proxy server forwards the request to Groww/Broker API using its **Static Server IP**.
- Returns the exact response back to Flutter.
- **Zero Database / Zero Storage**: Does NOT save any tokens, credentials, TOTP secrets, or order history.

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Environment Setup
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Settings inside `.env`:
- `PORT=3000`
- `NODE_ENV=production`
- `PROXY_SECRET_KEY=` *(Optional shared secret header `x-proxy-secret`)*

### 3. Run Locally / Development
```bash
npm run dev
```

### 4. Run Production
```bash
npm start
```

---

## 📡 API Endpoints

### 1. Check Server Static IP (`GET /api/v1/my-ip`)
Call this endpoint after deploying to your server to find the outbound Static IP address to whitelist in Groww API portal.
```bash
curl http://YOUR_SERVER_IP:3000/api/v1/my-ip
```

Response:
```json
{
  "success": true,
  "staticIp": "123.45.67.89",
  "message": "This is your backend server static IP. Register this IP in Groww API settings."
}
```

### 2. Universal Proxy (`POST /api/v1/proxy`)
Flutter sends any broker endpoint dynamically:
```json
{
  "targetUrl": "https://api.groww.in/v1/order/create",
  "method": "POST",
  "headers": {
    "Authorization": "Bearer <ACCESS_TOKEN>",
    "Content-Type": "application/json",
    "X-API-VERSION": "1.0"
  },
  "data": {
    "trading_symbol": "RELIANCE",
    "quantity": 1,
    "price": 2500,
    "validity": "DAY",
    "exchange": "NSE",
    "segment": "CASH",
    "product": "MIS",
    "order_type": "LIMIT",
    "transaction_type": "BUY"
  }
}
```

### 3. Groww Access Token Helper (`POST /api/v1/groww/access-token`)
Helper route for `/v1/token/api/access`.

### 4. Groww Order Helper (`POST /api/v1/groww/order`)
Helper route for `/v1/order/create`.

---

## 🐳 Docker & VPS Deployment

### Deploy using Docker:
```bash
docker build -t risk-proxy-backend .
docker run -d -p 3000:3000 --name proxy-bridge risk-proxy-backend
```

### Deploy using PM2 on Linux (Ubuntu/Debian VPS):
```bash
npm install -g pm2
pm2 start src/app.js --name "broker-proxy"
pm2 save
pm2 startup
```
