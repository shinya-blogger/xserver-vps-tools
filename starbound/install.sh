#!/bin/bash
# Copyright (C) 2023 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

function check_os() {
    . /etc/os-release
    if [ "$VERSION_ID" != "22.04" ]; then
        echo "This installer is only intended for Ubuntu 22.04."
        exit 1
    fi    
}

function input_steam_account() {
    while true; do
        read -p "Input Steam username: " steam_username
        if [ ! -z "$steam_username" ]; then
            break
        fi
    done

    while true; do
        read -p "Input Steam password: " steam_password
        if [ ! -z "$steam_password" ]; then
            break
        fi
    done
}

function install_server() {
    echo
    echo "Updating system packages..."
    export DEBIAN_FRONTEND=noninteractive
    dpkg --add-architecture i386 && \
    apt update -q && \
    apt upgrade -qq -y -o Dpkg::Options::="--force-confold"

    echo "Installing necessary dependencies..."
    apt install -qq -y curl wget file tar bzip2 gzip unzip bsdmainutils python3 util-linux ca-certificates binutils bc jq tmux netcat lib32gcc-s1 lib32stdc++6 libsdl2-2.0-0:i386 

    echo steam steam/license note '' | sudo debconf-set-selections
    echo steam steam/question select "I AGREE" | sudo debconf-set-selections
    apt install -y steamcmd

    echo "Creating a user for the server..."
    useradd -m sbserver

    echo "Installing Starbound Server..."
    sudo -u sbserver bash -c "cd /home/sbserver; wget -q -O linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && rm -f sbserver && bash linuxgsm.sh sbserver && mkdir -p lgsm/config-lgsm/sbserver && echo \"steamuser='${steam_username}'\" > lgsm/config-lgsm/sbserver/common.cfg && echo \"steampass='${steam_password}'\" >> lgsm/config-lgsm/sbserver/common.cfg && ./sbserver auto-install"

    echo "Creating systemd service file for Starbound..."
    cat > /etc/systemd/system/starbound-server.service <<EOL
[Unit]
Description=Starbound Server
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=sbserver
WorkingDirectory=/home/sbserver
RemainAfterExit=yes
ExecStart=/home/sbserver/sbserver start
ExecStop=/home/sbserver/sbserver stop
Restart=no

[Install]
WantedBy=multi-user.target
EOL

    echo "Reloading systemd manager configuration..."
    systemctl daemon-reload

    echo "Enabling Starbound server service..."
    systemctl enable starbound-server

    echo "Starting the Starbound server..."
    systemctl start starbound-server

    status=`systemctl is-active starbound-server`
    if [ "$status" == "active" ]; then
        echo "Starbound server installation and service setup complete."
    else
        echo "Starbound server installation failed."
    fi
}


echo "Starbound server Installer for Xserver VPS"
echo

check_os
input_steam_account
install_server