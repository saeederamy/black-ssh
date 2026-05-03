
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
<div align="center">

# 🐧 Black-SSH Linux CLI | Smart Balancer Daemon (V10)

![Linux](https://img.shields.io/badge/OS-Linux%20(Ubuntu/Debian)-orange.svg?style=for-the-badge)
![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Stable-success.svg?style=for-the-badge)

</div>

The **Black-SSH Linux Edition** is a powerful, fully automated background daemon designed for Linux servers. It features an interactive command-line interface (CLI) and works as a Smart Load Balancer to keep your SOCKS5 proxy alive 24/7.

Developed to bring the power of the V10 UI to headless servers!

---

## ✨ Features

* **⚙️ Systemd Daemon:** Runs silently in the background as a Linux service (`blackssh-balancer.service`), ensuring 100% uptime even after server reboots.
* **☁️ Cloud Subscription Sync:** Add your custom JSON URL. The daemon will auto-fetch and update your servers before every connection cycle.
* **⚡ Latency-Based Routing:** Automatically pings all servers (TCP) and routes traffic through the node with the lowest latency.
* **🛡️ Live Watchdog Monitor:** Continuously monitors the SSH process and the local SOCKS port. If the tunnel freezes or drops, it instantly kills and restarts the connection.
* **🎛️ Interactive CLI Menu:** A beautiful, easy-to-use terminal UI to add manual servers, configure settings, and view live logs.

---

## 🚀 Quick Auto-Install

Run the following command in your terminal as `root`. It will automatically install all dependencies (`sshpass`, `jq`, `curl`, `netcat`), setup the systemd service, and launch the CLI menu:

```bash
bash <(curl -sL https://raw.githubusercontent.com/saeederamy/black-ssh/main/install.sh))
```

> **Note:** If you already have it installed, running this command again will safely update the core files without deleting your saved servers.

---

## 🛠️ Usage & Commands

Once installed, you can open the interactive manager at any time from anywhere in your terminal by simply typing:

```bash
black-ssh
```

### Main Menu Options:
* **Start Smart Balancer Engine:** Starts the background daemon.
* **Stop Balancer Engine:** Stops all routing and kills active SSH sessions.
* **Balancer Settings:** Configure your local SOCKS port, Reconnect Timer, Live Monitor toggle, and Cloud JSON URL.
* **Add/Delete Manual Server:** Add custom servers directly via the terminal if you don't want to use the Cloud URL.
* **View Live Logs:** Watch the daemon's activity in real-time (Watchdog checks, Ping results, etc.).

---

## ☁️ Cloud JSON Format

If you are using the Cloud Sync feature (Option 3 in the menu), ensure your hosted `.json` file follows this exact structure:

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
    "user": "admin",
    "password": "StrongPassword2"
  }
}
```

<br>

<div align="center">
<i>Developed with ❤️ by Saeed Eramy</i>
</div>


## 💖 Support the Project

If this tool has helped you manage your Windows services more efficiently, consider supporting its development. Your donations help keep the project updated and maintained.

### 💰 Crypto Donations

You can support me by sending **Litecoin** or **TON** to the following addresses:

| Asset | Wallet Address |
| :--- | :--- |
| **Litecoin (LTC)** | `ltc1qxhuvs6j0suvv50nqjsuujqlr3u4ekfmys2ydps` |
| **TON Network** | `UQAHI_ySJ1HTTCkNxuBB93shfdhdec4LSgsd3iCOAZd5yGmc` |

---

### 🌟 Other Ways to Help
* **Give a Star:** If you can't donate, simply giving this repository a ⭐ **Star** means a lot and helps others find this project.
* **Feedback:** Open an issue if you encounter bugs or have suggestions for improvements.

> **Note:** Please double-check the address before sending. Crypto transactions are irreversible. Thank you for your generosity!
