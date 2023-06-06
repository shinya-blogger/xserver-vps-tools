#!/bin/bash

declare -r CONFIG_DIR="/etc/systemd/system/rust-server.service.d"
declare -r CONFIG_FILE="$CONFIG_DIR/override.conf"
declare -r DEFAULT_CONFIG="/etc/systemd/system/rust-server.service"

declare -r OXIDE_URL="https://umod.org/games/rust/download/develop"
declare -r TEMP_OXIDE_FILE="/tmp/Oxide.Rust-linux.zip"

declare -r RUST_SERVER_DIR="/home/steam/rust_server"

declare -r -a MAPS=("Procedural Map" "Barren" "HapisIsland" "CraggyIsland" "SavasIsland" "SavasIsland_koth")

config_updated=false

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -d "$RUST_SERVER_DIR" ]; then
        die "This server is not a Rust Server by Xserver VPS."
    fi
}

function create_default_config() {
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[Service]" > $CONFIG_FILE
        echo "ExecStart=" >> $CONFIG_FILE
        grep -E "^ExecStart=" "$DEFAULT_CONFIG" >> "$CONFIG_FILE"
    fi
}

function update_config_oxide() {
    value="$1"

    create_default_config

    sed -i '/^ExecPreStart=/d' "$CONFIG_FILE"
    if [ "$value" == "true" ]; then
        apt-get -y -q install unzip
        exec_pre_start="ExecPreStart=curl -sSL -o $TEMP_OXIDE_FILE $OXIDE_URL && unzip -o $TEMP_OXIDE_FILE -d $RUST_SERVER_DIR && chown -R steam:steam $RUST_SERVER_DIR/RustDedicated_Data/"
        sed -i -E "/^ExecStart=$/i\\${exec_pre_start}" "$CONFIG_FILE"
    fi

    config_updated=true

    systemctl daemon-reload
}

function update_config_param() {
    param="$1"
    value="$2"
    valuetype="$3"

    create_default_config

    if [ "$valuetype" == "string" ]; then
        value="\"$value\""
    fi

    if grep -q -E "^ExecStart=\/.+ \\$param " "$CONFIG_FILE"; then
        sed -i -E "s/^(ExecStart=\/.+ \\$param +)(\"[^\"]*\"|[^\" ]+)/\\1$value/" "$CONFIG_FILE"
    else
        sed -i -E "s/^(ExecStart=\/.+)$/\\1 $param $value/" "$CONFIG_FILE"
    fi

    config_updated=true

    systemctl daemon-reload
}

function change_hostname() {
    while true; do
        read -p "Input Server Hostname: " hostname
        if [ -z "$hostname" ]; then
            break
        else
            update_config_param "+server.hostname" "$hostname" "string"
            break
        fi
    done
}

function change_map() {
    while true; do
        for i in "${!MAPS[@]}"; do 
            echo "$((i+1)): ${MAPS[i]}"
        done
        read -p "Select Map(1-${#MAPS[@]}): " map_number
        if [ -z "$map_number" ]; then
            break
        elif [[ $map_number =~ ^[0-9]+$ ]] && [ $map_number -ge 1 ] && [ $map_number -le ${#MAPS[@]} ]; then
            map="${MAPS[$((map_number-1))]}"
            update_config_param "+server.level" "$map" "string"
            break
        fi
        echo "Invalid choice."
    done
}

function change_world_size() {
    while true; do
        read -p "Input World Size(1000-6000): " worldsize
        if [ -z "$worldsize" ]; then
            break
        elif [[ $worldsize =~ ^[0-9]+$ ]] && [ $worldsize -ge 1000 ] && [ $worldsize -le 6000 ]; then
            update_config_param "+server.worldsize" "$worldsize" "number"
            break
        fi
        echo "Invalid world size."
    done
}

function change_max_players() {
    while true; do
        read -p "Input Max Players: " maxplayers
        if [ -z "$maxplayers" ]; then
            break
        elif [[ $maxplayers =~ ^[0-9]+$ ]] && [ $maxplayers -ge 1 ]; then
            update_config_param "+server.maxplayers" "$maxplayers" "number"
            break
        fi
        echo "Invalid map players."
    done

}

function toggle_pve() {
    while true; do
        read -p "Enable PvE? (y/n): " pve
        if [ -z "$pve" ]; then
            break
        elif [ "$pve" == "y" ] || [ "$pve" == "Y" ]; then
            update_config_param "+server.pve" "true" "boolean"
            break
        elif [ "$pve" == "n" ] || [ "$pve" == "N"  ]; then
            update_config_param "+server.pve" "false" "boolean"
            break
        fi
        echo "Invalid choice."
    done
}

function activate_oxide() {
    while true; do
        read -p "Activate Oxide? (y/n): " activate
        if [ -z "$activate" ]; then
            break
        elif [ "$activate" == "y" ]; then
            update_config_oxide "true"
            break
        elif [ "$activate" == "n" ]; then
            update_config_oxide "false"
            break
        fi
        echo "Invalid choice."
    done
}

function quit() {
    if [ "$config_updated" == "true" ]; then
        restart_server
    fi

    exit 0
}

function restart_server() {
    local yes_no

    read -p "Restart Server? (y/n): " yes_no

    if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
        echo "Restarting Rust Server ..."
        systemctl restart rust-server
    fi
}

function main_menu() {
    echo "Rust Server Configutation Tool for Xserver VPS"

    while true; do
        echo
        echo "1. Change Server Hostname"
        echo "2. Change Map"
        echo "3. Change World Size"
        echo "4. Change Max Players"
        echo "5. Enable/Disable PvE"
        echo "6. Activate Oxide"
        echo "q. Quit"
        read -p "Please enter your choice(1-6,q): " choice

        case $choice in
            1) change_hostname ;;
            2) change_map ;;
            3) change_world_size ;;
            4) change_max_players ;;
            5) toggle_pve ;;
            6) activate_oxide ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

check_xserver_vps
main_menu
