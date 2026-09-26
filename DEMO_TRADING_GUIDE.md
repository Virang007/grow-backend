# Demo Trading & Broker Testing Guide

This guide explains how to test the application using pre-configured Demo Trading API keys and external brokers.

---

## 1. Pre-Configured Demo Credentials (MegaBull API)

Your app comes pre-configured with **MegaBull API (Demo)** so you don't need to manually type keys for testing:

- **Broker Name**: MegaBull API (Demo)
- **Base Server URL**: `https://api.megabull.in`
- **API Key**: `d35a226d-5b3a-44d7-a954-2db87bd069a7`
- **Account ID**: `MB-DEMO-99`
- **Environment**: Sandbox / Paper
- **Status**: Pre-Connected (1 Active Connection)

---

## 2. Free External Demo Trading APIs & Links

| Broker / Provider | Supported Type | How to Get Free Demo API Keys | Free API Link |
| :--- | :--- | :--- | :--- |
| **MegaBull API** *(Pre-Configured)* | Demo Trading API | Pre-loaded in app with endpoint `https://api.megabull.in` | `https://api.megabull.in` |
| **Alpaca Trading** | US Stocks & Crypto | Sign up for free Alpaca account -> Switch to "Paper Trading" -> Generate API Key & Secret. | [alpaca.markets](https://alpaca.markets) |
| **Dhan HQ Sandbox** | Indian Stocks & F&O | Sign up on Dhan -> Go to Dhan Web -> Profile -> DhanHQ API -> Generate Sandbox Access Token & Client ID. | [dhan.co](https://dhan.co) |
| **Zerodha Kite Sandbox** | Indian Stocks | Log in to Kite Connect developer portal -> Create Sandbox app -> Copy API Key & API Secret. | [kite.trade](https://kite.trade) |
| **Binance Futures Testnet** | Crypto Spot & Futures | Log in with GitHub or email -> Generate Testnet API Key & Secret instantly without KYC. | [testnet.binancefuture.com](https://testnet.binancefuture.com) |
| **Interactive Brokers (IBKR)** | Global Stocks & Options | Open IBKR Paper Trading Account -> Enable API Gateway in Trader Workstation (TWS) -> Local Port `7497`. | [interactivebrokers.com](https://interactivebrokers.com) |
| **Custom Broker API** | Any Custom REST API | Use your local or third-party paper trading server URL. | Custom Endpoint |

---

## 3. Step-by-Step Instructions to Test in the App

### Step 1: Open the App
Launch the app on your device or emulator.

### Step 2: Navigate to Broker Settings Page
1. Tap the **Connect Broker** tab on the bottom navigation bar (or tap **1 Connected** on the top app bar).
2. Notice **MegaBull API (Demo)** is already active and pre-configured!

### Step 3: Connect Additional Custom Brokers
1. Tap **+ Connect Any Custom Broker** or **Custom**.
2. Input any broker name, base URL, client ID, and API keys.
3. Tap **Save & Connect Broker**.

### Step 4: Perform Test Trades & Track Watchlist
1. Go back to the **Stock Tracker** tab.
2. Use the **Top Search Bar** to search any ticker (e.g. `AAPL`, `NVDA`, `RELIANCE`, `BTC-USD`).
3. Tap the **Bookmark Icon** to save it to your Watchlist.
4. Tap any saved stock to open the **Stock Price Detail Modal**.
5. Tap **BUY** or **SELL** to execute paper test trades.

---

*All credentials are stored locally on your device with AES-256 encryption.*
