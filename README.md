# BBTicker

**Your crypto portfolio at a glance — right in the macOS menu bar.**

BBTicker is a lightweight macOS menu bar app that shows your exchange wallet balance in real time. Connect your exchange API keys, see your equity and maintenance margin, and monitor your positions without opening a browser.

<p align="center">
  <img src="Documentation/screenshot-menu.png" alt="BBTicker Menu Bar" width="400"/>
</p>

---

## Features

- **Live menu bar equity display** — formatted as a native menu bar label (e.g. `1,234.5`)
- **Maintenance margin level dot** — color-coded indicator (green → yellow → red) so you always know your risk at a glance
- **Equity & balance detail in the popover** — plus maintenance margin percentage and seconds since last update
- **API key expiration warnings** — never get surprised by an expired key
- **Stale data indicator** — dimmed display when the connection drops, so you know the number is not current
- **Pro refresh speeds** — upgrade to 1-second, 5-second, or 10-second polling (free tier: 15 seconds)
- **Extendable exchange support** — currently supports Bybit; built on a protocol-driven architecture so new exchanges can be added easily
- **Wallet type selection** — unified trading account support
- **API environment selection** — switch between production, testnet, and demo environments without touching your keys
- **Secure keychain storage** — API keys are encrypted in the macOS Keychain
- **Auto-reconnection** — exponential backoff on network failures with smart retry logic
- **iOS companion app** — also available on iPhone with Siri voice commands ("Hey Siri, what's my BBTicker balance?")

---

## Supported Exchanges

| Exchange | Wallet Types |
|---|---|
| **Bybit** | Unified |

BBTicker is built on a **protocol-driven exchange registry** (via [LLCore](https://github.com/beemol/LLCore)). Adding a new exchange means implementing a request builder and response parser — the rest of the app works without changes. KuCoin and Binance support is in progress.

---

## Installation

### Mac App Store

*Coming soon*

The Mac App Store build is sandboxed, automatically updated by macOS, and verified by Apple.

---

## Setup — Connecting Your Exchange

### Step 1: Create read‑only API keys on Bybit

BBTicker only needs **read access** to your account. Never grant trade or withdrawal permissions.

1. Log into [bybit.com](https://www.bybit.com) → Account → API Management
2. Click **Create New API Key**
3. Name it "BBTicker" (optional)
4. Enable **Read-Write → Account → wallet** (read-only)
5. Set **No IP restriction** or whitelist your IP
6. Save the key and secret

### Step 2: Add credentials to BBTicker

1. Click the BBTicker menu bar icon → **Settings**
2. Select your exchange from the dropdown
3. Choose the **API Environment** (production is the default; use testnet for simulated funds)
4. Paste your **API Key** and **API Secret**
5. Click **Save Credentials**
6. You'll see a success popup — your balance now appears in the menu bar!

> API keys are stored per exchange **and** environment — so you can keep separate production and testnet keys and switch between them from Settings.

---

## Usage

### Menu Bar

| What you see | What it means |
|---|---|
| `1,234.5` (white) | Connected, equity is fresh |
| `1,234.5` (gray) | Stale — no recent updates from the exchange |
| `0.0` (gray) | Disconnected or no credentials configured |
| **🟢 dot** | Maintenance margin < 50% — safe |
| **🟠 dot** | Maintenance margin 50–70% — warning |
| **🔴 dot** | Maintenance margin > 70% — high risk |

The margin level dot requires **BBTicker Pro** and can be toggled in Settings.

### Popover (click the menu bar label)

- **Exchange name & wallet type** — top of the popover
- **Network & API status** — green dot = connected, red = error
- **API key expiration** — warns when your key is about to expire
- **Equity, Balance, Maintenance Margin %** — live values
- **Last updated counter** — seconds since the most recent successful update
- **Settings** — opens the settings window
- **Connect/Disconnect** — manually control the exchange connection

### Settings

- **Exchange & Wallet Type** — switch between exchanges and wallet types
- **API Environment** — switch between production, testnet, and demo environments
- **API Credentials** — enter or delete exchange API keys
- **How to create an API key** — step-by-step instructions inside the app
- **Widget Settings** (iOS) — configure the home screen widget refresh interval
- **Siri Setup** (iOS) — enable voice commands to check your balance

---

## BBTicker Pro

A one-time purchase unlocks:

| Feature | Free | Pro |
|---|---|---|
| Balance refresh rate | 15 seconds | 1, 5, or 10 seconds |
| Margin level dot in menu bar | ❌ | ✅ (green/amber/red) |

To purchase: **Settings → Pro section → Unlock**.

Restore a previous purchase: **Settings → Restore**.

---

## Privacy & Security

- **API keys are stored in the macOS Keychain** — encrypted at rest and never transmitted except directly to your exchange over HTTPS
- **Read‑only permissions only** — the app cannot trade or withdraw from your account
- **No data leaves your device** except to the exchange APIs you configure
- **Analytics off by default** — Firebase Analytics is included but disabled until explicit consent is granted; no usage data is collected without your permission
- **App Sandbox** — the Mac App Store build runs in macOS sandbox for defense-in-depth
- See [PrivacyInfo.xcprivacy](bbticker/PrivacyInfo.xcprivacy) for the full privacy manifest

---

## Building from Source

```bash
git clone https://github.com/beemol/bbticker.git
open bbticker.xcodeproj
```

Select the **bbticker** scheme and the **My Mac** destination, then **Build & Run** (⌘R).

Dependencies are managed via Swift Package Manager and resolve automatically on first build.

---

## Architecture

BBTicker follows **Unidirectional Data Flow (UDF)** for its state management:

```
Action → Store.send(_:) → Effect (async) → State Mutation → @Observable → View Rerender
```

Key design decisions:
- `@Observable` for reactive state in SwiftUI views (no Combine publishers)
- Actors for concurrency-safe services (`IAPManager`, `CredentialManager`, `AnalyticsManager`)
- File‑system‑synchronized Xcode groups for minimal `pbxproj` churn
- `LLApiService` / `LLCore` libraries encapsulate exchange‑specific logic so adding a new exchange is just implementing protocols

---

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CHANGELOG.md](CHANGELOG.md)
- [Privacy Policy](https://beemol.github.io/bbticker-releases/privacy.html)

---

## Contact

- **Contact:** [beemol.github.io/bbticker-releases/contact](https://beemol.github.io/bbticker-releases/contact.html)

---

## License

BBTicker © 2025-2026 Aleh Fiodarau. All rights reserved.
