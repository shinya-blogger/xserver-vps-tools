#!/bin/bash
# Copyright (C) 2024 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

USERNAME=steam
INI_FILEPATH=/home/steam/island-GameUserSettings.ini

function check_os() {
    . /etc/os-release
    if [ "$VERSION_ID" != "22.04" ]; then
        echo "This installer is only intended for Ubuntu 22.04."
        exit 1
    fi    
}

function check_ini_initialized() {
    if [ -f "$INI_FILEPATH" ]; then
        if  grep -q -E "^SessionName=.+" $INI_FILEPATH; then
            return 0
        fi
    fi
    return 1
}

function update_motd() {
    if [ ! -f /etc/motd ]; then
        while ! check_ini_initialized; do
            sleep 1
        done

        IPADDRESS=`ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1`
        SESSIONNAME=`cat $INI_FILEPATH | grep -E "^SessionName=.+" | cut -d= -f2`

        cat > /etc/motd << EOL
============================================        
ARK: Survival Ascended Server Information

IP Address:       ${IPADDRESS}
Server Directory: /home/${USERNAME}/steamapps/common/ARK Survival Ascended Dedicated Server
Session Name:     ${SESSIONNAME}
============================================
EOL
    fi
}

function install_server() {

    export DEBIAN_FRONTEND=noninteractive
    apt upgrade -qq -y -o Dpkg::Options::="--force-confold"
    
    echo steam steam/license note '' | sudo debconf-set-selections
    echo steam steam/question select "I AGREE" | sudo debconf-set-selections

    bash <(wget -qO- https://raw.githubusercontent.com/cdp1337/ARKSurvivalAscended-Linux/main/server-install-debian12.sh)

    update_motd
    cat /etc/motd
}




echo "ARK: Survival Ascended Server Installer for Xserver VPS"
echo

check_os
install_server