#!/bin/bash

# =======================================================
# BLACK-SSH CORE CLI MANAGER | V10 (Cloud & Balancer)
# Developed by: Saeed Eramy
# GitHub: https://github.com/saeederamy/black-ssh
# =======================================================

APP_DIR="/etc/black-ssh"
SRV_MANUAL="$APP_DIR/servers/manual"
SRV_CLOUD="$APP_DIR/servers/cloud"
CONF_FILE="$APP_DIR/settings.conf"
BIN_PATH="/usr/local/bin/black-ssh"
BALANCER_BIN="/usr/local/bin/black-ssh-balancer"
SVC_FILE="/etc/systemd/system/blackssh-balancer.service"
UPDATE_URL="https://raw.githubusercontent.com/saeederamy/black-ssh/main/install.sh"

C='\033[0;36m' LC='\033[1;36m' W='\033[1;37m' R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' GR='\033[1;30m' NC='\033[0m'

# ----------------- AUTO-INSTALLATION -----------------
if [[ "$0" != "$BIN_PATH" && "$1" != "--daemon" ]]; then
    clear
    echo -e "${LC}>> Installing BLACK-SSH V10 (Developed by Saeed Eramy)...${NC}"
    mkdir -p "$SRV_MANUAL" "$SRV_CLOUD"
    
    # نصب پیش‌نیازهای حیاتی (jq برای خواندن کلود، netcat برای پینگ)
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y sshpass curl jq netcat-openbsd > /dev/null 2>&1
    
    # ایجاد تنظیمات پیش‌فرض اگر وجود نداشت
    if [ ! -f "$CONF_FILE" ]; then
        echo -e "SOCKS=40\nTIMER=5\nMONITOR=1\nCLOUD_URL=\"\"" > "$CONF_FILE"
    fi
    
    curl -sL $UPDATE_URL -o $BIN_PATH
    chmod +x $BIN_PATH
    
    # ساخت فایل هسته لود بالانسر (Daemon)
    cat << 'EOF' > $BALANCER_BIN
#!/bin/bash
APP_DIR="/etc/black-ssh"
source "$APP_DIR/settings.conf"
SSH_PID=""

ping_tcp() {
    local start=$(date +%s%N)
    if nc -w 2 -z "$1" "$2" 2>/dev/null; then
        local end=$(date +%s%N)
        echo $(( (end - start) / 1000000 ))
    else
        echo 9999
    fi
}

sync_cloud() {
    if [ -n "$CLOUD_URL" ]; then
        echo "[$(date +'%H:%M:%S')] Fetching Cloud Servers..."
        rm -f "$APP_DIR"/servers/cloud/*.conf
        JSON=$(curl -sL -m 10 "$CLOUD_URL")
        if echo "$JSON" | jq . >/dev/null 2>&1; then
            for name in $(echo "${JSON}" | jq -r 'keys[]'); do
                IP=$(echo "${JSON}" | jq -r ".[\"${name}\"].host")
                PORT=$(echo "${JSON}" | jq -r ".[\"${name}\"].port // 22")
                USER=$(echo "${JSON}" | jq -r ".[\"${name}\"].user // \"root\"")
                PASS=$(echo "${JSON}" | jq -r ".[\"${name}\"].password")
                echo -e "IP=$IP\nPORT=$PORT\nUSER=$USER\nPASS=$PASS" > "$APP_DIR/servers/cloud/$name.conf"
            done
            echo "[$(date +'%H:%M:%S')] Cloud Sync Successful."
        else
            echo "[$(date +'%H:%M:%S')] Cloud Sync Failed (Invalid JSON or Network)."
        fi
    fi
}

while true; do
    sync_cloud
    
    BEST_SRV=""
    BEST_PING=9999
    BEST_IP=""
    BEST_PORT=""
    BEST_USER=""
    BEST_PASS=""
    
    echo "[$(date +'%H:%M:%S')] Analyzing best routes..."
    for conf in "$APP_DIR"/servers/manual/*.conf "$APP_DIR"/servers/cloud/*.conf; do
        [ ! -f "$conf" ] && continue
        source "$conf"
        NAME=$(basename "$conf" .conf)
        
        LATENCY=$(ping_tcp "$IP" "$PORT")
        echo " - $NAME : ${LATENCY}ms"
        
        if [ "$LATENCY" -lt "$BEST_PING" ]; then
            BEST_PING=$LATENCY
            BEST_SRV=$NAME
            BEST_IP=$IP
            BEST_PORT=$PORT
            BEST_USER=$USER
            BEST_PASS=$PASS
        fi
    done
    
    if [ -n "$BEST_SRV" ] && [ "$BEST_PING" -ne 9999 ]; then
        echo "[$(date +'%H:%M:%S')] Connecting to Best Server: $BEST_SRV ($BEST_PING ms)"
        
        # قطع کردن اتصال قبلی
        [ -n "$SSH_PID" ] && kill -9 $SSH_PID 2>/dev/null
        
        # اتصال جدید به همراه بایندینگ روی 0.0.0.0
        export SSHPASS="$BEST_PASS"
        sshpass -e ssh -N -D 0.0.0.0:$SOCKS -p $BEST_PORT -o "ServerAliveInterval 10" -o "ServerAliveCountMax 3" -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" $BEST_USER@$BEST_IP &
        SSH_PID=$!
        
        echo "[$(date +'%H:%M:%S')] Tunnel UP on port $SOCKS. Grace period 8s..."
        sleep 8
        
        # حلقه مانیتورینگ و تایمر (Timer)
        LOOPS=$(( TIMER * 60 / 2 ))
        for (( i=1; i<=LOOPS; i++ )); do
            sleep 2
            # Live Monitor Check
            if [ "$MONITOR" = "1" ]; then
                if ! nc -w 1 -z 127.0.0.1 $SOCKS 2>/dev/null; then
                    echo "[$(date +'%H:%M:%S')] LIVE MONITOR: Port Dead! Restarting Tunnel..."
                    kill -9 $SSH_PID 2>/dev/null
                    break
                fi
            fi
            # Process Crash Check
            if ! kill -0 $SSH_PID 2>/dev/null; then
                echo "[$(date +'%H:%M:%S')] LIVE MONITOR: SSH Process Crashed!"
                break
            fi
        done
        echo "[$(date +'%H:%M:%S')] Timer reached or tunnel dropped. Recalculating..."
    else
        echo "[$(date +'%H:%M:%S')] No servers available or all DOWN. Retrying in 10s..."
        sleep 10
    fi
done
EOF
    chmod +x $BALANCER_BIN

    # ساخت سرویس
    cat <<SRV > $SVC_FILE
[Unit]
Description=Black-SSH Smart Balancer Daemon
After=network.target

[Service]
ExecStart=$BALANCER_BIN
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SRV
    systemctl daemon-reload
    
    echo -e "${G}[+] Installed successfully!${NC}"
    echo -e "${W}>> Type '${LC}black-ssh${W}' to open the manager.${NC}"
    sleep 2
    exec $BIN_PATH
    exit 0
fi

source "$CONF_FILE"

# ----------------- UI FUNCTIONS -----------------
draw_logo() {
    clear
    echo -e "${LC}"
    echo ' ██████╗ ██╗      █████╗  ██████╗██╗  ██╗       ███████╗███████╗██╗  ██╗'
    echo ' ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝       ██╔════╝██╔════╝██║  ██║'
    echo ' ██████╔╝██║     ███████║██║     █████╔╝  █████╗███████╗███████╗███████║'
    echo ' ██╔══██╗██║     ██╔══██║██║     ██╔═██╗  ╚════╝╚════██║╚════██║██╔══██║'
    echo ' ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗       ███████║███████║██║  ██║'
    echo ' ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝       ╚══════╝╚══════╝╚═╝  ╚═╝'
    echo -e "${GR}        V10 Cloud Edition | Developed by Saeed Eramy${NC}\n"
}

add_manual_server() {
    draw_logo
    echo -e "${C}--- [ ADD MANUAL SERVER ] ---${NC}\n"
    read -p "Profile Name (e.g. Germany-1): " NAME
    [ -z "$NAME" ] && return
    read -p "Target IP: " IP
    read -p "SSH Port [22]: " PORT
    PORT=${PORT:-22}
    read -p "Username [root]: " USER
    USER=${USER:-root}
    read -p "Password: " PASS
    
    echo -e "IP=$IP\nPORT=$PORT\nUSER=$USER\nPASS=$PASS" > "$SRV_MANUAL/$NAME.conf"
    echo -e "\n${G}[+] Server '$NAME' added successfully!${NC}"; sleep 1
}

delete_manual_server() {
    draw_logo
    echo -e "${C}--- [ DELETE MANUAL SERVER ] ---${NC}\n"
    ls -1 "$SRV_MANUAL" | sed -e 's/\.conf$//'
    echo ""
    read -p "Enter Profile Name to delete: " DNAME
    if [ -f "$SRV_MANUAL/$DNAME.conf" ]; then
        rm "$SRV_MANUAL/$DNAME.conf"
        echo -e "${G}[+] Deleted!${NC}"; sleep 1
    else
        echo -e "${R}[!] Not found.${NC}"; sleep 1
    fi
}

settings_menu() {
    while true; do
        draw_logo
        echo -e "${Y}--- [ BALANCER SETTINGS ] ---${NC}\n"
        echo -e " 1) SOCKS5 Port        [ ${G}$SOCKS${NC} ]"
        echo -e " 2) Reconnect Timer    [ ${G}$TIMER Minutes${NC} ]"
        echo -e " 3) Live Monitor       [ ${G}$([ "$MONITOR" = "1" ] && echo "ON" || echo "OFF")${NC} ]"
        echo -e " 4) Cloud Sync URL     [ ${G}${CLOUD_URL:-"Not Set"}${NC} ]"
        echo -e " 0) Back to Main Menu\n"
        read -p "Select setting to change: " OPT
        case $OPT in
            1) read -p "New SOCKS Port: " SOCKS ;;
            2) read -p "New Timer (Minutes): " TIMER ;;
            3) read -p "Enable Monitor? (1=ON, 0=OFF): " MONITOR ;;
            4) read -p "Enter Cloud JSON URL (or leave blank to clear): " CLOUD_URL ;;
            0) 
                echo -e "SOCKS=$SOCKS\nTIMER=$TIMER\nMONITOR=$MONITOR\nCLOUD_URL=\"$CLOUD_URL\"" > "$CONF_FILE"
                systemctl restart blackssh-balancer.service 2>/dev/null
                return 
            ;;
        esac
    done
}

# ----------------- MAIN MENU -----------------
while true; do
    draw_logo
    
    STATUS=$(systemctl is-active blackssh-balancer.service)
    if [ "$STATUS" == "active" ]; then
        echo -e " Engine Status: ${G}● RUNNING (Monitoring Active)${NC}\n"
    else
        echo -e " Engine Status: ${GR}○ STOPPED${NC}\n"
    fi

    echo -e " ${W}1)${NC} ⚡ Start Smart Balancer Engine"
    echo -e " ${W}2)${NC} 🛑 Stop Balancer Engine"
    echo -e " ${W}3)${NC} ⚙️  Balancer Settings (Cloud URL, Timer, Monitor)"
    echo -e " ${W}4)${NC} 🖥️  Add Manual Server"
    echo -e " ${W}5)${NC} 🗑️  Delete Manual Server"
    echo -e " ${W}6)${NC} 📜 View Live Logs (Monitor Activity)"
    echo -e " ${W}7)${NC} 🔄 Update Black-SSH"
    echo -e " ${R}0)${NC} Exit\n"
    read -p "Select option: " OPTION
    
    case $OPTION in
        1) 
            systemctl start blackssh-balancer.service
            systemctl enable blackssh-balancer.service >/dev/null 2>&1
            echo -e "${G}[+] Engine Started in background!${NC}"; sleep 1 
            ;;
        2) 
            systemctl stop blackssh-balancer.service
            systemctl disable blackssh-balancer.service >/dev/null 2>&1
            pkill -f "ssh -N -D 0.0.0.0:$SOCKS"
            echo -e "${R}[*] Engine Stopped.${NC}"; sleep 1 
            ;;
        3) settings_menu ;;
        4) add_manual_server ;;
        5) delete_manual_server ;;
        6) 
            clear
            echo -e "${LC}>> Press CTRL+C to exit logs...${NC}\n"
            journalctl -u blackssh-balancer.service -f 
            ;;
        7) 
            echo -e "\n${C}[*] Fetching latest update from GitHub...${NC}"
            curl -sL -o /tmp/black-ssh-update.sh $UPDATE_URL
            if [ $? -eq 0 ] && grep -q "BLACK-SSH" /tmp/black-ssh-update.sh; then
                mv /tmp/black-ssh-update.sh $BIN_PATH
                chmod +x $BIN_PATH
                echo -e "${G}[+] Updated successfully!${NC}"; sleep 1
                exec $BIN_PATH
            else
                echo -e "${R}[!] Update failed.${NC}"; sleep 2
            fi
            ;;
        0) clear; exit 0 ;;
    esac
done
