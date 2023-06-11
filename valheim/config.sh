#!/bin/bash

declare -r SYSTEMD_FILE="/etc/systemd/system/valheim_server.service"
declare -r SYSTEMD_DROPIN_DIR="/etc/systemd/system/valheim_server.service.d"
declare -r SYSTEMD_DROPIN_FILE="$SYSTEMD_DROPIN_DIR/override.conf"

declare -r VALHEIM_SERVER_DIR="/home/steam/Valheim"
declare -r VALHEIM_SERVER_CONFIG_DIR="/home/steam/.config/unity3d/IronGate/Valheim"
declare -r VALHEIM_SERVER_ADMIN_FILE="$VALHEIM_SERVER_CONFIG_DIR/adminlist.txt"

declare -r STARTUP_VANNILA_FILE="$VALHEIM_SERVER_DIR/valheim_server.sh"
declare -r STARTUP_BEPINEX_FILE="$VALHEIM_SERVER_DIR/valheim_server_bepinex.sh"
declare -r DEFAULT_STARTUP_BEPINEX_FILE="$VALHEIM_SERVER_DIR/start_server_bepinex.sh"

declare -r TEMP_BEPINEX_FILE="/tmp/$$.bepinex.zip"

config_updated=false

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -d "$VALHEIM_SERVER_DIR" ] && [ ! -f "$STARTUP_VANNILA_FILE" ]; then
        die "This server is not a Valheim Server by Xserver VPS."
    fi
}

function check_bepinex_installed() {
    if [ -f "$STARTUP_BEPINEX_FILE" ]; then
        return 1
    else
        return 0
    fi
}







function create_default_config() {
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[Service]" > $CONFIG_FILE
        echo "ExecStart=" >> $CONFIG_FILE
        grep -E "^ExecStart=" "$DEFAULT_CONFIG_FILE" >> "$CONFIG_FILE"
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




function update_server_config() {
    param="$1"
    value="$2"
    valuetype="$3"

    if [ "$valuetype" == "string" ]; then
        value="\"$value\""
    fi

    if grep -q -E "^[^#]+\/valheim_server.x86_64.* $param " "$STARTUP_VANNILA_FILE"; then
        sed -i -E "s/^([^#]+\/valheim_server.x86_64.* $param +)(\"[^\"]*\"|[^\" ]+)/\\1$value/" "$STARTUP_VANNILA_FILE"
    else
        sed -i -E "s/^([^#]+\/valheim_server.x86_64.*)$/\\1 $param $value/" "$STARTUP_VANNILA_FILE"
    fi

    config_updated=true
}

function print_current_server_config() {
    param="$1"

    DEFULT_SERVER_CONFIG="./valheim_server.x86_64 -name \"Dedicated\" -world \"Valheim_World\" -public 1 -saveinterval 1800"
    STARTUP_SERVER_CONFIG=$(grep -E "/valheim_server.x86_64 " "$STARTUP_VANNILA_FILE" | grep -v -E "^#")

    line=$(echo -e -n "$DEFULT_SERVER_CONFIG\n$STARTUP_SERVER_CONFIG" | grep -E " $param " | tail -1)
    value=$(echo "$line" | sed -E "s/^.+ $param +(\"([^\"]*)\"|([^\" ]+)).*$/\\2\\3/")

    echo -n $value
}

function change_hostname() {
    echo
    current_val=$(print_current_server_config "-name")
    echo "Current Server Hostname: $current_val"

    while true; do
        read -p "Input Server Hostname: " hostname
        if [ -z "$hostname" ]; then
            break
        else
            update_server_config "-name" "$hostname" "string"
            break
        fi
    done
}

function change_password() {
    echo
    current_val=$(print_current_server_config "-password")
    echo "Current Password: $current_val"

    while true; do
        read -p "Input Password: " password
        if [ -z "$password" ]; then
            break
        else
            update_server_config "-password" "$password" "string"
            break
        fi
    done
}

function change_world() {
    echo
    current_val=$(print_current_server_config "-world")
    echo "Current World Name: $current_val"

    while true; do
        read -p "Input World Name: " world
        if [ -z "$world" ]; then
            break
        else
            update_server_config "-world" "$world" "string"
            break
        fi
    done
}

function add_admin() {
    echo
    echo "Current Admin Players:"
    grep -E -v "^\/\/" "$VALHEIM_SERVER_ADMIN_FILE"

    while true; do
        read -p "Input Admin Player's SteamId64: " admin
        if [ -z "$admin" ]; then
            break
        elif grep -q -E "^$admin$" "$VALHEIM_SERVER_ADMIN_FILE"; then
            echo "Already registered as admin player."    
            break
        else 
            echo "$admin" >> "$VALHEIM_SERVER_ADMIN_FILE"
            break
        fi
    done
}

function download_bepinex() {
    bepinex_url="https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2105/"
    curl -sSL -o "$TEMP_BEPINEX_FILE" "$bepinex_url"
}

function extract_bepinex() {
    local temp_dir=/tmp/$$.unzip
    
    apt-get -y -q install unzip
    unzip -qq -o "$TEMP_BEPINEX_FILE" -d "$temp_dir"
    rsync -a --remove-source-files $temp_dir/BepInExPack_Valheim/ "$VALHEIM_SERVER_DIR/"
    chown -R steam:steam "$VALHEIM_SERVER_DIR/"
    rm -Rf "$temp_dir"
}

function create_startup_script_for_bepinex() {
    line=$(grep -E "/valheim_server.x86_64 " "$STARTUP_VANNILA_FILE" | grep -v -E "^#")

    line_number=$(grep -n -E "/valheim_server.x86_64 " "$DEFAULT_STARTUP_BEPINEX_FILE" | grep -v -E "^#" | cut -d : -f 1)
    head_lines=$((line_number - 1))
    tail_lines=$((line_number + 1))
    {
        head -n $head_lines $DEFAULT_STARTUP_BEPINEX_FILE;
        echo $line;
        tail -n +$tail_lines $DEFAULT_STARTUP_BEPINEX_FILE;
    } > $STARTUP_BEPINEX_FILE

    chmod +x $STARTUP_BEPINEX_FILE
    chown steam:steam $STARTUP_BEPINEX_FILE
}

function delete_startup_script_for_bepinex() {
    rm -f $STARTUP_BEPINEX_FILE
}

function create_default_systemd_dropin() {
    mkdir -p "$SYSTEMD_DROPIN_DIR"

    if [ ! -f "$SYSTEMD_DROPIN_FILE" ]; then
        echo "[Service]" > $SYSTEMD_DROPIN_FILE
    fi
}

function update_systemd_config_for_bepinex() {
    create_default_systemd_dropin
    sed -i '/^ExecStart=/d' "$SYSTEMD_DROPIN_FILE"
    echo "ExecStart=$STARTUP_BEPINEX_FILE" >> "$SYSTEMD_DROPIN_FILE"
    systemctl daemon-reload
}

function update_systemd_config_for_vanilla() {
    create_default_systemd_dropin
    sed -i '/^ExecStart=/d' "$SYSTEMD_DROPIN_FILE"
    systemctl daemon-reload
}

function update_systemd_config_autoupdate() {
    local autoupdate=$1

    create_default_systemd_dropin
    sed -i '/^ExecPreStart=/d' "$SYSTEMD_DROPIN_FILE"

    if [ "$autoupdate" == "false" ]; then
        echo "ExecPreStart=" >> "$SYSTEMD_DROPIN_FILE"
    fi
    systemctl daemon-reload
}

function install_bepinex_core() {
    download_bepinex 
    extract_bepinex
    create_startup_script_for_bepinex
    update_systemd_config_for_bepinex
}

function uninstall_bepinex_core() {
    delete_startup_script_for_bepinex
    update_systemd_config_for_vanilla
}

function install_bepinex() {
    echo
    check_bepinex_installed
    installed=$?
    
    if [ "$installed" == 1 ]; then
        echo "BePinEx already installed"
    fi

    while true; do
        read -p "Install BePinEx? (y/n): " answer
        if [ -z "$answer" ]; then
            break
        elif [ "$answer" == "y" ]; then
            install_bepinex_core
            echo "Install completed."
            break
        elif [ "$answer" == "n" ]; then
            break
        fi
        echo "Invalid choice."
    done
}

function uninstall_bepinex() {
    echo
    check_bepinex_installed
    installed=$?
    
    if [ "$installed" == 0 ]; then
        echo "BePinEx is not installed."
        return
    fi

    while true; do
        read -p "Uninstall BePinEx? (y/n): " answer
        if [ -z "$answer" ]; then
            break
        elif [ "$answer" == "y" ]; then
            uninstall_bepinex_core
            echo "Uninstall completed."
            break
        elif [ "$answer" == "n" ]; then
            break
        fi
        echo "Invalid choice."
    done
}

function change_auto_update() {
    echo

    while true; do
        read -p "Auto update on server startup? (y/n): " autoupdate
        if [ -z "$autoupdate" ]; then
            break
        elif [ "$autoupdate" == "y" ]; then
            update_systemd_config_autoupdate "true"
            break
        elif [ "$autoupdate" == "n" ]; then
            update_systemd_config_autoupdate "false"
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
        echo "Restarting Rust Server ..."
        systemctl restart rust-server
    fi
}

function main_menu() {
    echo "Valheim Server Configutation Tool for Xserver VPS"

    while true; do
        echo
        echo "1. Change Server Hostname"
        echo "2. Change Password"
        echo "3. Change World"
        echo "4. Add Admin Player"
        echo "5. Install BePinEx"
        echo "6. Uninstall BePinEx"
        echo "7. Enable/Disable Auto-Update"
        echo "q. Quit"
        read -p "Please enter your choice(1-8,q): " choice

        case $choice in
            1) change_hostname ;;
            2) change_password ;;
            3) change_world ;;
            4) add_admin ;;
            5) install_bepinex ;;
            6) uninstall_bepinex ;;
            7) change_auto_update ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

check_xserver_vps
main_menu
