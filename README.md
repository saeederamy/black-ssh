
# ⬛ Black-SSH | Ultimate Smart Balancer Client

![Version](https://img.shields.io/badge/Version-10.0%20(Creator%20Edition)-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)
![Python](https://img.shields.io/badge/Python-3.10+-yellow.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Black-SSH** is an advanced, native Windows SSH tunneling client equipped with a Smart Load Balancer, Cloud Synchronization, and a modern Glass UI. Developed to provide a seamless, highly-available proxy experience.

---

## 🌟 Key Features

* **⚡ Smart Load Balancer:** Automatically tests TCP latency for all saved servers and seamlessly connects to the fastest one.
* **☁️ Cloud Config Sync:** Fetch and update your server configurations remotely from a custom JSON URL. No need to add servers manually!
* **👁️ Live Monitor (Anti-Drop):** Continuously monitors the SSH process and SOCKS5 port health. Instantly reconnects if the tunnel drops or freezes.
* **🌍 Global System Proxy:** Modify Windows Registry on-the-fly to route all OS traffic (Browsers, Telegram, etc.) through the active SSH tunnel.
* **🛡️ Custom SSH Ports:** Fully supports non-standard SSH ports for enhanced security.
* **📋 Bulletproof Clipboard:** Features a custom Direct-Memory Copy/Paste engine, bypassing typical UI framework bugs on Windows.
* **🎨 Neon Glass UI:** A beautiful dark theme with dynamic neon accents (Blue, Orange, Red, Green) reflecting real-time connection status.

## 🚀 How to Use

### Installation
1. Go to the [Releases](../../releases) page and download the latest `BlackSSH_App.exe`.
2. Run the executable. (No Python installation required!)

### Manual Configuration
1. Navigate to the **⚙️ Server Manager** tab.
2. Enter your server details (IP, Port, Username, Password) and click **Save**.
3. Go back to the **Dashboard** and click **START SMART BALANCER**.

### Cloud Configuration (For Providers)
Host a `.json` file on your server (e.g., `https://your-domain.com/configs.json`) with the following format:

```json
{
  "Germany-VIP": {
    "host": "192.168.1.10",
    "port": "22",
    "user": "root",
    "password": "StrongPassword1"
  },
  "Finland-Backup": {
    "host": "192.168.1.20",
    "port": "2022",
    "user": "root",
    "password": "StrongPassword2"
  }
}
```
```bash
bash <(curl -Ls https://raw.githubusercontent.com/saeederamy/black-ssh/main/install.sh)
```
