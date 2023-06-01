#!/bin/bash

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

check_xserver_vps
generate_service_file "TheIsland"
systemctl daemon-reload

echo "You can use GameUserSettings.ini for SessionName, ServerPassword and ServerAdminPassword."
