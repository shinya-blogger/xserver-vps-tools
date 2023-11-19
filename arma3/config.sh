#!/bin/bash
# Copyright (C) 2023 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

declare -r SYSTEMD_DEFAULT_CONFIG_FILE="/etc/systemd/system/arma3-server.service"
declare -r SYSTEMD_OVERRIDE_CONFIG_DIR="/etc/systemd/system/arma3-server.service.d"
declare -r SYSTEMD_OVERRIDE_CONFIG_FILE="$SYSTEMD_OVERRIDE_CONFIG_DIR/override.conf"

declare -r SERVER_DIR="/home/steam/arma3"
declare -r SERVER_CONFIG_FILE="$SERVER_DIR/server.cfg"
declare -r MOD_DIR="$SERVER_DIR/mods"

declare -r BATTLEYE_CONFIG_FILE="/home/steam/arma3/battleye/launch/battleye/beserver.cfg"

config_updated=false

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -d "$SERVER_DIR" ]; then
        die "This server is not an ARMA 3 Server by Xserver VPS."
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
    escaped_value="${value//\//\\/}"
    valuetype="$3"

    create_systemd_override_config

    if grep -q -E "^ExecStart=\/.+ \"$param=" "$SYSTEMD_OVERRIDE_CONFIG_FILE"; then
        sed -i -E "s/^(ExecStart=\/.+ \"$param=)([^\"]*)/\\1$escaped_value/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    else
        sed -i -E "s/^(ExecStart=\/.+)$/\\1 \"$param=$escaped_value\"/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
    fi

    config_updated=true

    systemctl daemon-reload
}

function delete_systemd_config_param() {
    param="$1"

    create_systemd_override_config

    if grep -q -E "^ExecStart=\/.+ \"$param=" "$SYSTEMD_OVERRIDE_CONFIG_FILE"; then
        sed -i -E "s/^(ExecStart=\/.+) \"$param=[^\"]*\"(.*)/\\1\\2/" "$SYSTEMD_OVERRIDE_CONFIG_FILE"
        config_updated=true
        systemctl daemon-reload
    fi
}

function print_current_systemd_config_param() {
    param="$1"

    DEFAULT_CONFIG=$(grep -E "^ExecStart=" $SYSTEMD_DEFAULT_CONFIG_FILE)
    OVERRIDE_CONFIG=""
    if [ -f "$SYSTEMD_OVERRIDE_CONFIG_FILE" ]; then
        OVERRIDE_CONFIG=$(grep -E "^ExecStart=" $SYSTEMD_OVERRIDE_CONFIG_FILE)
    fi

    line=$(echo -e -n "$DEFAULT_CONFIG\n$OVERRIDE_CONFIG" | grep -E "\"$param=" | tail -1)
    value=$(echo "$line" | sed -E "s/^.+ \"$param=([^\"]*)\".*$/\\1/")

    echo -n $value
}

function update_server_config_param() {
    param="$1"
    value="$2"
    escaped_value="${value//\//\\/}"

    if grep -q -E "^$param *=" "$SERVER_CONFIG_FILE"; then
        sed -i -E "s/(^$param *= *\")([^\"]*)\"/\\1$escaped_value\"/" "$SERVER_CONFIG_FILE"
    else
        echo "$param = \"$value\";" >> $SERVER_CONFIG_FILE
    fi

    config_updated=true
}

function print_current_server_config_param() {
    param="$1"

    line=$(grep -E "^$param *=" "$SERVER_CONFIG_FILE" | tail -1)
    value=$(echo "$line" | sed -E "s/(^[^=]+= *\")([^\"]+).+$/\\2/")

    echo -n $value
}

function create_beserver_config() {
    if [ ! -f "$BATTLEYE_CONFIG_FILE" ]; then
        touch "$BATTLEYE_CONFIG_FILE"
        chown steam:steam "$BATTLEYE_CONFIG_FILE"
    fi
}

function update_beserver_config_param() {
    param="$1"
    value="$2"

    create_beserver_config

    if grep -q -E "^$param " "$BATTLEYE_CONFIG_FILE"; then
        sed -i -E "s/^$param .+$/$param $value/" "$BATTLEYE_CONFIG_FILE"
    else
        echo "$param $value" >> $BATTLEYE_CONFIG_FILE
    fi

    config_updated=true
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
    current_val=$(print_current_server_config_param "password")
    echo "Current Join Password: $current_val"

    while true; do
        read -p "Input New Join Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_server_config_param "password" "$password"
            break
        fi
    done
}

function change_admin_password() {
    echo
    current_val=$(print_current_server_config_param "passwordAdmin")
    echo "Current Admin Password: $current_val"

    while true; do
        read -p "Input New Admin Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_server_config_param "passwordAdmin" "$password"
            break
        fi
    done
}

function activate_rcon() {
    echo

    while true; do
        read -p "Activate RCON? (y/n): " activate
        if [ -z "$activate" ]; then
            break
        elif [ "$activate" == "y" ]; then
            activate_rcon_core
            break
        elif [ "$activate" == "n" ]; then
            break
        fi
        echo "Invalid choice."
    done
}

function activate_rcon_core() {
    while true; do
        read -p "Input New RCON Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_systemd_config_param "-bepath" "battleye" "string"
            update_beserver_config_param "RConPassword" "$password"
            update_beserver_config_param "RConPort" "2301"
            break
        fi
        echo "Invalid choice."
    done
}

function deactivate_rcon() {
    echo

    while true; do
        read -p "Deactivate RCON? (y/n): " deactivate
        if [ -z "$deactivate" ]; then
            break
        elif [ "$deactivate" == "y" ]; then
            delete_systemd_config_param "-bepath" 
            break
        elif [ "$deactivate" == "n" ]; then
            break
        fi
        echo "Invalid choice."
    done
}

function enable_mods() {
    echo

    if [ ! -d "$MOD_DIR" ]; then
        mkdir -p "$MOD_DIR"
        chown steam:steam "$MOD_DIR"
    fi

    installed_mods=()
    mod_count=0

    for dir in "$MOD_DIR"/*; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            if [[ "$dir_name" == *" "* ]]; then
                continue
            fi
            ((mod_count++))
            installed_mods+=("mods/$dir_name")
        fi
    done

    echo "Mod directory: $MOD_DIR"
    echo "Number of mods installed: $mod_count"

    while true; do
        echo

        mod_param=`print_current_systemd_config_param "-mod"`
        IFS=';' read -ra enabled_mods <<< "$mod_param"

        counter=1
        for installed_mod in "${installed_mods[@]}"; do
            dir_name=$(basename "$installed_mod")

            status="Disabled"

            for enabled_mod in "${enabled_mods[@]}"; do
                if [[ "$enabled_mod" == *"$installed_mod" ]]; then
                    status="Enabled"
                    break
                fi
            done

            echo "$counter. $dir_name - $status"

            ((counter++))
        done
        echo "q. Quit"

        read -p "Select number of mod to enable/disable(1-${mod_count},q): " mod_number
        if [ -z "$mod_number" ]; then
            break
        elif [ "$mod_number" == "q" ]; then
            break
        elif [[ $mod_number =~ ^[0-9]+$ ]] && [ $mod_number -ge 1 ] && [ $mod_number -le ${mod_count} ]; then
            mod="${installed_mods[$((mod_number-1))]}"
            if printf '%s\n' "${enabled_mods[@]}" | grep -qx "$mod"; then
                enabled_mods=( $( printf "%s\n" "${enabled_mods[@]}" | grep -vx "$mod" ) )
            else
                enabled_mods+=("$mod")
                chown -R steam:steam "${SERVER_DIR}/${mod}"
            fi
            enabled_mods=( $( printf "%s\n" "${enabled_mods[@]}" | sort ) )
            mod_param=$(IFS=';'; echo "${enabled_mods[*]}")
            if [ "$mod_param" == "" ]; then
                delete_systemd_config_param "-mod"
            else
                update_systemd_config_param "-mod" "$mod_param" "string"
            fi
        else    
            echo "Invalid choice."
        fi
        
    done

}

function update_server() {
    echo

    while true; do
        read -p "Update Arma3 Server? (y/n): " update
        if [ -z "$update" ]; then
            return
        elif [ "$update" == "y" ]; then
            break
        elif [ "$update" == "n" ]; then
            return
        fi
        echo "Invalid choice."
    done

    read -p "Input steam account: " steam_account
    if [ -z "$steam_account" ]; then
        return
    fi

    read -p "Input steam password: " steam_password
    if [ -z "$steam_password" ]; then
        return
    fi

    echo
    echo "Stopping Arma 3 Server ..."
    systemctl stop arma3-server

    echo
    sudo -u steam /usr/games/steamcmd +@sSteamCmdForcePlatformType linux +force_install_dir /home/steam/arma3 +login ${steam_account} ${steam_password} +app_update 233780 +quit

    echo
    echo "Starting Arma 3 Server ..."
    systemctl start arma3-server
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
        echo "Restarting Arma 3 Server ..."
        systemctl restart arma3-server
    fi
}


function main_menu() {
    echo "Arma 3 Server Configutation Tool for Xserver VPS"

    while true; do
        echo
        echo "1. Change Server Hostname"
        echo "2. Change Join Password"
        echo "3. Change Admin Password"
        echo "4. Activate RCON"
        echo "5. Deactivate RCON"
        echo "6. Enable/Disable mods"
        echo "7. Update server"
        echo "q. Quit"
        read -p "Please enter your choice(1-7,q): " choice

        case $choice in
            1) change_hostname ;;
            2) change_join_password ;;
            3) change_admin_password ;;
            4) activate_rcon ;;
            5) deactivate_rcon ;;
            6) enable_mods ;;
            7) update_server ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

check_xserver_vps
main_menu
