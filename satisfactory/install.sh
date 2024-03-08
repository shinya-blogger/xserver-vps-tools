#!/bin/bash
# Copyright (C) 2024 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

USERNAME=sfserver
PASSWORD_LENGTH=12

function check_os() {
    . /etc/os-release
    if [ "$VERSION_ID" != "22.04" ]; then
        echo "This installer is only intended for Ubuntu 22.04."
        exit 1
    fi    
}

function install_server() {
    if [ ! -f /etc/motd ]; then
        IPADDRESS=`ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1`

        cat > /etc/motd << EOL
============================================        
Satisfactory Server Information

IP Address:       ${IPADDRESS}
Server Directory: /home/${USERNAME}/serverfiles
User:             ${USERNAME}
Password:         \${PASSWORD}
============================================
EOL
    fi

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

    if ! id "${USERNAME}" &>/dev/null; then
        echo "Creating a user for the server..."
        PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | fold -w ${PASSWORD_LENGTH} | head -n 1)
        useradd -m "${USERNAME}"
        echo "${USERNAME}:${PASSWORD}" | chpasswd
        sed -i'' "s/\${PASSWORD}/${PASSWORD}/g" /etc/motd
    fi

    echo "Installing Satisfactory Server..."
    sudo -u ${USERNAME} bash -c "cd /home/${USERNAME}; wget -q -O linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && rm -f sfserver && bash linuxgsm.sh sfserver && ./sfserver auto-install"

    echo "Creating systemd service file for Satisfactory..."
    cat > /etc/systemd/system/satisfactory-server.service <<EOL
[Unit]
Description=Satisfactory Server
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=${USERNAME}
WorkingDirectory=/home/${USERNAME}
RemainAfterExit=yes
ExecStart=/home/${USERNAME}/sfserver start
ExecStop=/home/${USERNAME}/sfserver stop
Restart=no

[Install]
WantedBy=multi-user.target
EOL

    echo "Reloading systemd manager configuration..."
    systemctl daemon-reload

    echo "Enabling Satisfactory server service..."
    systemctl enable satisfactory-server

    echo "Starting the Satisfactory server..."
    systemctl start satisfactory-server

    status=`systemctl is-active satisfactory-server`
    if [ "$status" == "active" ]; then
        echo "Satisfactory server installation and service setup complete."
        cat /etc/motd
    else
        echo "Satisfactory server installation failed."
    fi
}


echo "Satisfactory server Installer for Xserver VPS"
echo

check_os
install_server