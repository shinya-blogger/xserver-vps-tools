#!/bin/bash
# Copyright (C) 2024 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

declare -r SYSTEMD_DEFAULT_CONFIG_FILE="/etc/systemd/system/palworld-server.service"
declare -r SYSTEMD_OVERRIDE_CONFIG_DIR="/etc/systemd/system/palworld-server.service.d"
declare -r SYSTEMD_OVERRIDE_CONFIG_FILE="$SYSTEMD_OVERRIDE_CONFIG_DIR/override.conf"

declare -r SERVER_DIR="/home/steam/Palworld"
declare -r DEFAULT_SERVER_CONFIG_FILE="$SERVER_DIR/DefaultPalWorldSettings.ini"
declare -r SERVER_CONFIG_FILE="$SERVER_DIR/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini"

config_updated=false

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -d "$SERVER_DIR" ]; then
        die "This server is not a Palworld Server built on Xserver VPS."
    fi
}

function create_systemd_override_config() {
    mkdir -p "$SYSTEMD_OVERRIDE_CONFIG_DIR"

    if [ ! -f "$SYSTEMD_OVERRIDE_CONFIG_FILE" ]; then
        echo "[Service]" > $SYSTEMD_OVERRIDE_CONFIG_FILE
        echo "ExecStart=" >> $SYSTEMD_OVERRIDE_CONFIG_FILE
        grep -E "^ExecStart=" "$SYSTEMD_DEFAULT_CONFIG_FILE" >> "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    fi
}

function update_systemd_config_param() {
    param="$1"
    value="$2"

    create_systemd_override_config

    if grep -q -E "^ExecStart=\/.+ \\$param=" "$SYSTEMD_OVERRIDE_CONFIG_FILE"; then
        sed -i -E "s/^(ExecStart=\/.+ \\$param=)([^ ]+)/\\1$value/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    else
        sed -i -E "s/^(ExecStart=\/.+)$/\\1 $param=$value/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    fi

    config_updated=true

    systemctl daemon-reload
}

function remove_systemd_config_param() {
    param="$1"

    create_systemd_override_config

    if grep -q -E "^ExecStart=\/.+ \\$param=" "$SYSTEMD_OVERRIDE_CONFIG_FILE"; then
        sed -i -E "s/^(ExecStart=\/.+ )\\$param=[^ ]+(.+)$/\\1\\2/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    fi

    config_updated=true

    systemctl daemon-reload
}

function print_current_systemd_config_param() {
    param="$1"

    SYSTEMD_DEFAULT_CONFIG=$(grep -E "^ExecStart=" $SYSTEMD_DEFAULT_CONFIG_FILE)
    SYSTEMD_OVERRIDE_CONFIG=""
    if [ -f "$SYSTEMD_OVERRIDE_CONFIG_FILE" ]; then
        SYSTEMD_OVERRIDE_CONFIG=$(grep -E "^ExecStart=" $SYSTEMD_OVERRIDE_CONFIG_FILE)
    fi

    line=$(echo -e -n "$SYSTEMD_DEFAULT_CONFIG\n$SYSTEMD_OVERRIDE_CONFIG" | grep -E " \\$param=" | tail -1)
    value=$(echo "$line" | sed -E "s/^.+ \\$param=([^ ]+).*$/\\1/")

    echo -n $value
}

function create_server_config() {
    if ! grep -q -E "^OptionSettings=" "$SERVER_CONFIG_FILE"; then
        grep -v -E "^;" "$DEFAULT_SERVER_CONFIG_FILE" >> "$SERVER_CONFIG_FILE"
    fi
}

function update_server_config_param() {
    param="$1"
    value="$2"
    valuetype="$3"

    if [ "$valuetype" == "string" ]; then
        value="\"$value\""
    fi

    create_server_config

    if grep -q -E "^OptionSettings=\(([^=]+=(\"[^\"]*\"|[a-zA-Z0-9.]+),)*\\$param=" "$SERVER_CONFIG_FILE"; then
        sed -i -E "s/^(OptionSettings=.*[(,]\\$param=)(\"[^\"]*\"|[a-zA-Z0-9.]+)/\\1$value/" "$SERVER_CONFIG_FILE"
    else
        sed -i -E "s/^(OptionSettings=[^)]+)\)$/\\1,$param=$value)/" "$SERVER_CONFIG_FILE"
    fi

    config_updated=true
}

function print_current_server_config_param() {
    param="$1"

    DEFAULT_SERVER_CONFIG=$(grep -E "^OptionSettings=" $DEFAULT_SERVER_CONFIG_FILE)
    SERVER_CONFIG=$(grep -E "^OptionSettings=" $SERVER_CONFIG_FILE)

    line=$(echo -e -n "$DEFAULT_SERVER_CONFIG\n$SERVER_CONFIG" | grep -E "[(,]\\$param=" | tail -1)
    value=$(echo "$line" | sed -E "s/^.+[(,]\\$param=(\"([^\")]*)\"|([^,)]+)).*$/\\2\\3/")

    echo -n $value
}


function toggle_community_server() {
    echo
    current_val=$(print_current_systemd_config_param "EpicApp")
    if [ "$current_val" == "PalServer" ]; then
        current_val="On"
    else
        current_val="Off"
    fi
    echo "Current comminity server: $current_val"

    while true; do
        read -p "Enable community server (y/n): " community_server
        if [ -z "$community_server" ]; then
            break
        elif [ "$community_server" == "y" ] || [ "$community_server" == "Y" ]; then
            update_systemd_config_param "EpicApp" "PalServer"
            break
        elif [ "$community_server" == "n" ] || [ "$community_server" == "N"  ]; then
            remove_systemd_config_param "EpicApp"
            break
        fi
        echo "Invalid choice."
    done
}

function change_server_name() {
    echo
    current_val=$(print_current_server_config_param "ServerName")
    echo "Current server name: $current_val"

    while true; do
        read -p "Input server name: " servername
        if [ -z "$servername" ]; then
            break
        else
            update_server_config_param "ServerName" "$servername" "string"
            break
        fi
    done
}

function change_server_password() {
    echo
    current_val=$(print_current_server_config_param "ServerPassword")
    echo "Current server password: $current_val"

    read -p "Input server password: " password
    update_server_config_param "ServerPassword" "$password" "string"
}

function change_admin_password() {
    echo
    current_val=$(print_current_server_config_param "AdminPassword")
    echo "Current admin password: $current_val"

    read -p "Input admin password: " password
    update_server_config_param "AdminPassword" "$password" "string"
}

function change_max_players() {
    echo
    current_val=$(print_current_server_config_param "ServerPlayerMaxNum")
    echo "Current max players: $current_val"

    while true; do
        read -p "Input max players: " maxplayers
        if [ -z "$maxplayers" ]; then
            break
        elif [[ $maxplayers =~ ^[0-9]+$ ]] && [ $maxplayers -ge 1 ]; then
            update_server_config_param "ServerPlayerMaxNum" "$maxplayers" "number"
            break
        fi
        echo "Invalid max players."
    done

}

function toggle_rcon() {
    echo
    current_val=$(print_current_server_config_param "RCONEnabled")
    if [ "$current_val" == "True" ]; then
        current_val="On"
    else
        current_val="Off"
    fi
    echo "Current RCON: $current_val"

    while true; do
        read -p "Enable RCON? (y/n): " answer
        if [ -z "$answer" ]; then
            break
        elif [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
            update_server_config_param "RCONEnabled" "True" "boolean"
            break
        elif [ "$answer" == "n" ] || [ "$answer" == "N"  ]; then
            update_server_config_param "RCONEnabled" "False" "boolean"
            break
        fi
        echo "Invalid choice."
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
        echo "Restarting Palworld Server ..."
        systemctl restart palworld-server
    fi
}

function main_menu() {
    echo "Palworld Server Configutation Tool for Xserver VPS"

    while true; do
        echo
        echo "1. Enable/Disable Community Server"
        echo "2. Change Server Name"
        echo "3. Change Server Password"
        echo "4. Change Admin Password"
        echo "5. Change Max Players"
        echo "6. Enable/Disable RCON"
        echo "q. Quit"
        read -p "Please enter your choice(1-6,q): " choice

        case $choice in
            1) toggle_community_server ;;
            2) change_server_name ;;
            3) change_server_password ;;
            4) change_admin_password ;;
            5) change_max_players ;;
            6) toggle_rcon ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

check_xserver_vps
main_menu
