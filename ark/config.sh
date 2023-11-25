#!/bin/bash
# Copyright (C) 2023 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

declare -r SYSTEMD_DEFAULT_CONFIG_FILE="/etc/systemd/system/ark-server.service"

config_updated=false

function die() {
    local message=$1
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ -f /home/ark/Servers/ShooterGame/Binaries/Linux/ShooterGameServer ]; then
        return
    fi
    if [ -f /home/steam/ark/ShooterGame/Binaries/Linux/ShooterGameServer ]; then
        return
    fi
    die "This server is not an ARK Server by Xserver VPS."
}

function generate_service_file() {
    local map_name=$1
    local dir_path="/etc/systemd/system/ark-server.service.d"

    mkdir -p "$dir_path"

    cat << EOF > "$dir_path/override.conf"
[Service]
ExecStart=
ExecStart=/home/ark/Servers/ShooterGame/Binaries/Linux/ShooterGameServer $map_name?listen -server -log
EOF
}

function process_ver1() {
    generate_service_file "TheIsland"
    systemctl daemon-reload

    echo "You can use GameUserSettings.ini for SessionName, ServerPassword and ServerAdminPassword."
}

function update_systemd_config_param() {
    param="$1"
    value="$2"
    valuetype="$3"

    value="${value//\//\\/}"
    if [[ "$value" == *" "* ]]; then
        value="\"$value\""
    fi

    if grep -q -E "^ExecStart=\/.+ .+\?$param=" "$SYSTEMD_DEFAULT_CONFIG_FILE"; then
        sed -i -E "s/^(ExecStart=\/.+ .+\?$param=)(\"[^\"]*\"|[^ \"\?]*)/\\1$value/" "$SYSTEMD_DEFAULT_CONFIG_FILE"
    else
        sed -i -E "s/^(ExecStart=\/.+ .+(\?.+=(\"[^\"]*\"|[^ \"\?]*))*)/\\1\?$param=$value/" "$SYSTEMD_DEFAULT_CONFIG_FILE"
    fi

    config_updated=true

    systemctl daemon-reload
}

function print_current_systemd_config_param() {
    param="$1"

    line=$(grep -E "^ExecStart=" $SYSTEMD_DEFAULT_CONFIG_FILE | tail -1)
    value=$(echo "$line" | sed -E "s/^.+ .*\?$param=(\"([^\"]*)\"|([^ \"\?]*)).*$/\\2\\3/")

    echo -n $value
}


function change_hostname() {
    echo
    current_val=$(print_current_systemd_config_param "SessionName")
    echo "Current Server Name: $current_val"

    while true; do
        read -p "Input Server Name: " servername
        if [ -z "$servername" ]; then
            break
        else
            update_systemd_config_param "SessionName" "$servername"
            break
        fi
    done
}

function change_join_password() {
    echo
    current_val=$(print_current_systemd_config_param "ServerPassword")
    echo "Current Join Password: $current_val"

    while true; do
        read -p "Input New Join Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_systemd_config_param "ServerPassword" "$password"
            break
        fi
    done
}

function change_admin_password() {
    echo
    current_val=$(print_current_systemd_config_param "ServerAdminPassword")
    echo "Current Admin Password: $current_val"

    while true; do
        read -p "Input New Admin Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_systemd_config_param "ServerAdminPassword" "$password"
            break
        fi
    done
}

function quit() {
    echo

    if [ "$config_updated" == "true" ]; then
        restart_server
    fi

    exit 0
}

function restart_server() {
    local yes_no

    read -p "Restart Server? (y/n): " yes_no

    if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
        echo "Restarting ARK Server ..."
        systemctl restart ark-server
    fi
}

function main_menu() {
    echo "ARK Server Configutation Tool for Xserver VPS"

    while true; do
        echo
        echo "1. Change Server Hostname"
        echo "2. Change Join Password"
        echo "3. Change Admin Password"
        echo "q. Quit"
        read -p "Please enter your choice(1-3,q): " choice

        case $choice in
            1) change_hostname ;;
            2) change_join_password ;;
            3) change_admin_password ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

function process_ver2() {
    main_menu
}

check_xserver_vps

if [ -f /home/ark/Servers/ShooterGame/Binaries/Linux/ShooterGameServer ]; then
    process_ver1
else
    process_ver2
fi
