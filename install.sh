#!/bin/bash

# =======================================================
# BLACK-SSH CORE CLI MANAGER
# GitHub: https://github.com/saeederamy/black-ssh
# =======================================================

BIN_PATH="/usr/local/bin/black-ssh"
TUNNEL_DIR="/etc/black-ssh/tunnels"
UPDATE_URL="https://raw.githubusercontent.com/saeederamy/black-ssh/main/install.sh"

C='\033[0;36m' LC='\033[1;36m' W='\033[1;37m' R='\033[0;31m' G='\033[0;32m' GR='\033[1;30m' NC='\033[0m'

# ----------------- AUTO-INSTALLATION -----------------
# وقتی کاربر با curl اسکریپت را اجرا میکند، این بخش آن را در سیستم نصب میکند
if [[ "$0" != "$BIN_PATH" ]]; then
    clear
    echo -e "${LC}>> Installing BLACK-SSH from GitHub (saeederamy)...${NC}"
    mkdir -p $TUNNEL_DIR
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y autossh sshpass curl > /dev/null 2>&1
    
    curl -sL $UPDATE_URL -o $BIN_PATH
    chmod +x $BIN_PATH
    
    echo -e "${G}[+] Installed successfully!${NC}"
    echo -e "${W}>> Type '${LC}black-ssh${W}' to open the manager.${NC}"
    sleep 2
    exec $BIN_PATH
    exit 0
fi

# ----------------- FUNCTIONS -----------------
draw_logo() {
    clear
    echo -e "${LC}"
    echo ' ██████╗ ██╗      █████╗  ██████╗██╗  ██╗       ███████╗███████╗██╗  ██╗'
    echo ' ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝       ██╔════╝██╔════╝██║  ██║'
    echo ' ██████╔╝██║     ███████║██║     █████╔╝  █████╗███████╗███████╗███████║'
    echo ' ██╔══██╗██║     ██╔══██║██║     ██╔═██╗  ╚════╝╚════██║╚════██║██╔══██║'
    echo ' ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗       ███████║███████║██║  ██║'
    echo ' ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝       ╚══════╝╚══════╝╚═╝  ╚═╝'
    echo -e "${W}                   C O R E   M A N A G E R${NC}\n"
}

add_tunnel() {
    draw_logo
    echo -e "${C}--- [ ADD NEW TUNNEL ] ---${NC}\n"
    read -p "Enter Local SOCKS5 Port (e.g. 40): " SOCKS
    if [ -z "$SOCKS" ]; then return; fi
    if [ -f "$TUNNEL_DIR/$SOCKS.conf" ]; then
        echo -e "${R}[!] Port $SOCKS is already in use!${NC}"; sleep 2; return
    fi
    read -p "Target IP: " IP
    read -p "SSH Port [22]: " PORT
    PORT=${PORT:-22}
    read -p "Username [root]: " USER
    USER=${USER:-root}
    read -s -p "Target Password: " PASS
    echo -e "\n\n${GR}[*] Injecting keys...${NC}"
    
    mkdir -p ~/.ssh
    [ ! -f ~/.ssh/id_rsa ] && ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q
    export SSHPASS=$PASS
    sshpass -e ssh-copy-id -o StrictHostKeyChecking=no -p $PORT $USER@$IP > /dev/null 2>&1
    if [ $? -ne 0 ]; then echo -e "${R}[!] Auth failed! Check IP/Pass.${NC}"; sleep 3; return; fi
    
    echo -e "${GR}[*] Creating background service...${NC}"
    cat <<SRV > /etc/systemd/system/blackssh-${SOCKS}.service
[Unit]
Description=Black-SSH Tunnel Port $SOCKS
After=network.target
[Service]
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N -D 127.0.0.1:$SOCKS -p $PORT -o "ServerAliveInterval 15" -o "ServerAliveCountMax 3" -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" $USER@$IP
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
SRV

    systemctl daemon-reload
    systemctl enable blackssh-${SOCKS}.service > /dev/null 2>&1
    systemctl start blackssh-${SOCKS}.service
    echo "TARGET_IP=$IP" > "$TUNNEL_DIR/$SOCKS.conf"
    echo -e "${G}[+] Tunnel added and running on port $SOCKS!${NC}"; sleep 2
}

manage_tunnels() {
    draw_logo
    echo -e "${C}--- [ ACTIVE TUNNELS ] ---${NC}\n"
    count=0
    for conf in $TUNNEL_DIR/*.conf; do
        [ ! -e "$conf" ] && break
        count=$((count+1))
        SOCKS=$(basename "$conf" .conf)
        source "$conf"
        if [ "$(systemctl is-active blackssh-${SOCKS}.service)" == "active" ]; then
            LAT=$(curl -s -o /dev/null -w "%{time_total}" -x socks5h://127.0.0.1:$SOCKS -m 3 https://1.1.1.1 2>/dev/null)
            if [ -n "$LAT" ] && [ "$LAT" != "0.000" ]; then
                MS=$(awk "BEGIN {print int($LAT * 1000)}")
                PING="${G}${MS}ms${NC}"
            else PING="${R}DNS Error${NC}"; fi
            STAT="${G}ONLINE${NC}"
        else
            STAT="${R}OFFLINE${NC}"; PING="${GR}N/A${NC}"
        fi
        printf "${W}Port: ${LC}%-5s${W} | IP: ${LC}%-15s${W} | Status: %-15s | Ping: %s\n" "$SOCKS" "$TARGET_IP" "$STAT" "$PING"
    done
    [ $count -eq 0 ] && echo -e "${GR}No tunnels found.${NC}"
    
    echo -e "\n${GR}------------------------------------------------${NC}"
    read -p "Enter PORT to DELETE (or press Enter to go back): " DEL
    if [ -n "$DEL" ] && [ -f "$TUNNEL_DIR/$DEL.conf" ]; then
        systemctl stop blackssh-${DEL}.service > /dev/null 2>&1
        systemctl disable blackssh-${DEL}.service > /dev/null 2>&1
        rm /etc/systemd/system/blackssh-${DEL}.service "$TUNNEL_DIR/$DEL.conf"
        systemctl daemon-reload
        echo -e "${G}[+] Tunnel deleted.${NC}"; sleep 1
    fi
}

stop_all() {
    echo -e "\n${R}[*] Stopping all tunnels...${NC}"
    for conf in $TUNNEL_DIR/*.conf; do
        [ ! -e "$conf" ] && break
        SOCKS=$(basename "$conf" .conf)
        systemctl stop blackssh-${SOCKS}.service > /dev/null 2>&1
    done
    echo -e "${G}[+] All stopped.${NC}"; sleep 2
}

update_script() {
    echo -e "\n${C}[*] Fetching latest update from GitHub...${NC}"
    curl -sL -o /tmp/black-ssh-update.sh $UPDATE_URL
    if [ $? -eq 0 ] && grep -q "BLACK-SSH" /tmp/black-ssh-update.sh; then
        mv /tmp/black-ssh-update.sh $BIN_PATH
        chmod +x $BIN_PATH
        echo -e "${G}[+] Updated successfully!${NC}"
        sleep 2
        exec $BIN_PATH
    else
        echo -e "${R}[!] Update failed.${NC}"; sleep 2
    fi
}

# ----------------- MAIN MENU -----------------
while true; do
    draw_logo
    echo -e " ${W}1)${NC} Add New SSH Tunnel"
    echo -e " ${W}2)${NC} Manage Tunnels & Check Ping"
    echo -e " ${W}3)${NC} Stop All Tunnels"
    echo -e " ${W}4)${NC} Update Black-SSH"
    echo -e " ${R}0)${NC} Exit\n"
    read -p "Select option: " OPTION
    case $OPTION in
        1) add_tunnel ;; 
        2) manage_tunnels ;; 
        3) stop_all ;; 
        4) update_script ;;
        0) clear; exit 0 ;;
    esac
done
