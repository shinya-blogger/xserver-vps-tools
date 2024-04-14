#!/bin/bash
#
# ARK: Survival Ascended Server Configutation Tool for Xserver VPS
# Copyright (C) 2024 shinya-blogger https://github.com/shinya-blogger
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

declare -r SYSTEMD_DEFAULT_CONFIG_FILE="/etc/systemd/system/ark-island.service"
declare -r SYSTEMD_OVERRIDE_CONFIG_DIR="/etc/systemd/system/ark-island.service.d"
declare -r SYSTEMD_OVERRIDE_CONFIG_FILE="$SYSTEMD_OVERRIDE_CONFIG_DIR/override.conf"

declare -r -a MAPS=("TheIsland_WP" "ScorchedEarth_WP")

config_updated=false

function die() {
    local message=$1
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -f $SYSTEMD_DEFAULT_CONFIG_FILE ]; then
        die "This server is not an ARK: Survival Ascended Server built on Xserver VPS."
    fi
}

function create_systemd_override_config() {
    mkdir -p "$SYSTEMD_OVERRIDE_CONFIG_DIR"

    if [ ! -f "$SYSTEMD_OVERRIDE_CONFIG_FILE" ]; then
        echo "[Unit]" > $SYSTEMD_OVERRIDE_CONFIG_FILE
        echo "Description=" >> $SYSTEMD_OVERRIDE_CONFIG_FILE
        grep -E "^Description=" "$SYSTEMD_DEFAULT_CONFIG_FILE" >> "$SYSTEMD_OVERRIDE_CONFIG_FILE"
        echo "[Service]" >> $SYSTEMD_OVERRIDE_CONFIG_FILE
        echo "ExecStart=" >> $SYSTEMD_OVERRIDE_CONFIG_FILE
        grep -E "^ExecStart=" "$SYSTEMD_DEFAULT_CONFIG_FILE" >> "$SYSTEMD_OVERRIDE_CONFIG_FILE"
        config_updated=true
    fi
}

function update_systemd_override_config_mapname() {
    local map_name=$1
    local exec_start

    create_systemd_override_config

    sed -i -E "s/(^Description=.+\()(.+)(\))/\\1${map_name}\\3/g" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    sed -i -E "s/(^ExecStart=.+ArkAscendedServer.exe )(.+)(\?)/\\1${map_name}\\3/g" "$SYSTEMD_OVERRIDE_CONFIG_FILE"

    config_updated=true

    systemctl daemon-reload
}

function print_current_systemd_config_mapname() {
    local default_config=$(grep -E "^ExecStart=.+" $SYSTEMD_DEFAULT_CONFIG_FILE)
    local override_config=""

    if [ -f "$SYSTEMD_OVERRIDE_CONFIG_FILE" ]; then
        override_config=$(grep -E "^ExecStart=.+" $SYSTEMD_OVERRIDE_CONFIG_FILE)
    fi

    line=$(echo -e -n "$default_config\n$override_config\n" | grep -E "^ExecStart=.+" | tail -1)
    map_name=$(echo "$line" | sed -E "s/^.+ArkAscendedServer.exe (.+)\?.*$/\\1/")

    echo -n $map_name
}

function update_systemd_override_config_option() {
    param="$1"
    value="$2"
    valuetype="$3"

    value="${value//\//\\/}"
    if [[ "$value" == *" "* ]]; then
        value="\"$value\""
    fi

    create_systemd_override_config

    if grep -q -E "^ExecStart=.+ -$param=" "$SYSTEMD_OVERRIDE_CONFIG_FILE"; then
        sed -i -E "s/^(ExecStart=.+ -$param=)(\"[^\"]*\"|[^ \"\?]*)/\\1$value/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    else
        sed -i -E "s/^(ExecStart=.+)$/\\1 -$param=$value/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    fi

    config_updated=true

    systemctl daemon-reload
}

function print_current_systemd_config_option() {
    param="$1"

    local default_config=$(grep -E "^ExecStart=.+" $SYSTEMD_DEFAULT_CONFIG_FILE)
    local override_config=""

    if [ -f "$SYSTEMD_OVERRIDE_CONFIG_FILE" ]; then
        override_config=$(grep -E "^ExecStart=.+" $SYSTEMD_OVERRIDE_CONFIG_FILE)
    fi

    line=$(echo -e -n "$default_config\n$override_config\n" | grep -E "^ExecStart=.+ -$param" | tail -1)
    value=$(echo "$line" | sed -E "s/^.+ -$param=(\"([^\"]*)\"|([^ \"\?]*)).*$/\\2\\3/")

    echo -n $value
}

function change_map() {
    echo
    current_map=$(print_current_systemd_config_mapname)
    echo "Current Map: $current_map"

    while true; do
        for i in "${!MAPS[@]}"; do 
            echo "$((i+1)): ${MAPS[i]}"
        done
        read -p "Select Map(1-${#MAPS[@]}): " map_number
        if [ -z "$map_number" ]; then
            break
        elif [[ $map_number =~ ^[0-9]+$ ]] && [ $map_number -ge 1 ] && [ $map_number -le ${#MAPS[@]} ]; then
            map="${MAPS[$((map_number-1))]}"
            update_systemd_override_config_mapname "$map"
            break
        fi
        echo "Invalid choice."
    done
}

function change_mods_option() {
    echo
    current_mods=$(print_current_systemd_config_option "mods")
    echo "Current -mods option: $current_mods"

    read -p "Input -mods option: " mods
    update_systemd_override_config_option "mods" "$mods" "string"
}

function restart_server() {
    local yes_no
    read -p "Restart Server? (y/n): " yes_no

    if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
        echo "Restarting ARK: Survival Ascended Server ..."
        systemctl restart ark-island
    fi
}

function quit() {
    echo

    if [ "$config_updated" == "true" ]; then
        restart_server
    fi

    exit 0
}

function main_menu() {
    echo "ARK: Survival Ascended Server Configutation Tool for Xserver VPS"

    while true; do
        echo
        echo "1. Change Map"
        echo "2. Change -mods Option"
        echo "q. Quit"
        read -p "Please enter your choice(1-2,q): " choice

        case $choice in
            1) change_map ;;
            2) change_mods_option ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

check_xserver_vps
main_menu
