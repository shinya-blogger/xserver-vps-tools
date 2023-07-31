#!/bin/bash
# Copyright (C) 2023 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

declare -a maps=("TheIsland" "TheCenter" "Ragnarok" "Valguero" "CrystalIsles" "LostIsland" "Fjordur")

function die() {
    local message=$1
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -f /home/ark/Servers/ShooterGame/Binaries/Linux/ShooterGameServer ]; then
        die "This server is not an ARK Server by Xserver VPS."
    fi
}

function display_maps() {
    echo "ARK Map Selector for Xserver VPS"
    for i in "${!maps[@]}"; do 
       echo "$((i+1)): ${maps[i]}"
    done
}

function select_map() {
    local map_number
    read -p "Select Map (1-${#maps[@]}): " map_number

    if [[ $map_number =~ ^[0-9]+$ ]] && [ $map_number -ge 1 ] && [ $map_number -le ${#maps[@]} ]; then
        echo "Map '${maps[$((map_number-1))]}' is selected."
        generate_service_file "${maps[$((map_number-1))]}"
        systemctl daemon-reload
    else
        die "Invalid choice. Please select a valid map number."
    fi
}

function restart_server() {
    local yes_no
    read -p "Restart Server? (y/n): " yes_no

    if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
        echo "Restarting ARK Server ..."
        systemctl restart ark-server
    fi
}

generate_service_file() {
    local map_name=$1
    local dir_path="/etc/systemd/system/ark-server.service.d"

    mkdir -p "$dir_path"

    cat << EOF > "$dir_path/override.conf"
[Service]
ExecStart=
ExecStart=/home/ark/Servers/ShooterGame/Binaries/Linux/ShooterGameServer $map_name?listen -server -log
EOF
}

check_xserver_vps
display_maps
select_map
restart_server
