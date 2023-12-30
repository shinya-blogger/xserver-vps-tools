#!/bin/bash
# Copyright (C) 2023 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

declare -r SERVER_DIR="/home/steam/cs2_server"
declare -r SERVER_CONFIG_FILE="$SERVER_DIR/game/csgo/cfg/server.cfg"

config_updated=false

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -d "$SERVER_DIR" ]; then
        die "This server is not a Counter-Strike 2 Server by Xserver VPS."
    fi
}

function update_server_config_param() {
    param="$1"
    value="$2"
    escaped_value="${value//\//\\/}"
    valuetype="$3"

    if grep -q -E "^$param " "$SERVER_CONFIG_FILE"; then
        sed -i -E "s/^$param .+$/$param \"$escaped_value\"/" "$SERVER_CONFIG_FILE"
    else
        echo "$param \"$value\"" >> "$SERVER_CONFIG_FILE"
    fi

    config_updated=true
}

function delete_server_config_param() {
    param="$1"

    if grep -q -E "^$param " "$SERVER_CONFIG_FILE"; then
        sed -i -E "s/^$param .+$//" "$SERVER_CONFIG_FILE"
        config_updated=true
    fi
}

function print_current_server_config_param() {
    param="$1"

    line=$(grep -E "^$param " "$SERVER_CONFIG_FILE" | tail -1)
    value=$(echo "$line" | sed -E "s/^$param +(([^\"]+)|\"([^\"]+)\") *$/\\2\\3/")

    echo -n $value
}

function change_hostname() {
    echo
    current_val=$(print_current_server_config_param "hostname")
    echo "Current Server Hostname: $current_val"

    while true; do
        read -p "Input Server Hostname: " hostname
        if [ -z "$hostname" ]; then
            break
        else
            update_server_config_param "hostname" "$hostname"
            break
        fi
    done
}

function change_join_password() {
    echo
    current_val=$(print_current_server_config_param "sv_password")
    echo "Current Join Password: $current_val"

    while true; do
        read -p "Input New Join Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_server_config_param "sv_password" "$password"
            break
        fi
    done
}

function change_rcon_password() {
    echo
    current_val=$(print_current_server_config_param "rcon_password")
    echo "Current RCON Password: $current_val"

    while true; do
        read -p "Input New RCON Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_server_config_param "rcon_password" "$password"
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
        echo "Restarting Counter-Strike 2 Server ..."
        systemctl restart cs2
    fi
}


function main_menu() {
    echo "Counter-Strike 2 Server Configutation Tool for Xserver VPS"

    while true; do
        echo
        echo "1. Change Server Hostname"
        echo "2. Change Join Password"
        echo "3. Change RCON Password"
        echo "q. Quit"
        read -p "Please enter your choice(1-3,q): " choice

        case $choice in
            1) change_hostname ;;
            2) change_join_password ;;
            3) change_rcon_password ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

check_xserver_vps
main_menu
