#!/bin/bash
# Copyright (C) 2023 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

declare -r SDTD_SERVER_DIR="/home/steam/7dtd"
declare -r SDTD_SERVER_CONFIG_FILE="$SDTD_SERVER_DIR/serverconfig.xml"
declare -r SDTD_SERVER_SAVE_DIR="/home/steam/.local/share/7DaysToDie/Saves"
declare -r SDTD_SERVER_SERVER_ADMINFILE="$SDTD_SERVER_SAVE_DIR/serveradmin.xml"

declare -r -a REGIONS=("NorthAmericaEast" "NorthAmericaWest" "CentralAmerica" "SouthAmerica" "Europe" "Russia" "Asia" "MiddleEast" "Africa" "Oceania")
declare -r -a LANGUAGES=("Japanese" "Korean" "Chinese" "English")
declare -r -a VISIBILITIES=("Not Listed" "Only Shown to Friends" "Public")
declare -r -a DIFFICULTIES=("Scavenger" "Adventurer" "Nomad" "Warrior" "Survivalist" "Insane")
declare -r -a WORLDS=("RWG" "Navezgane" "PREGEN6k" "PREGEN8k" "PREGEN10k")

config_updated=false

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -d "$SDTD_SERVER_DIR" ] && [ ! -f "$SDTD_SERVER_CONFIG_FILE" ]; then
        die "This server is not a 7 Days to Die Server by Xserver VPS."
    fi
}

function init() {
    install_package xmlstarlet
}

function install_package() {
    local pkg=$1
    if ! dpkg -l | grep -q "$pkg"; then
		echo "Installing library ..."
		apt-get -qq update > /dev/null && apt-get -qq install "$pkg" > /dev/null
	fi
}

function update_server_config() {
    param="$1"
    value="$2"

    xmlstarlet ed --inplace -u "//property[@name='$param']/@value" -v "$value" "$SDTD_SERVER_CONFIG_FILE"

    config_updated=true
}

function print_current_server_config() {
    param="$1"

    value=$(xmlstarlet sel -t -v "//property[@name='$param']/@value" "$SDTD_SERVER_CONFIG_FILE")

    echo -n $value
}

function print_server_version() {
    (sleep 0.5s; echo "exit";) | telnet 127.0.0.1 8081 2>&1 | head | grep -E "Server version"
}

function execute_command() {
    cmd="$1"

    (sleep 0.5s; echo "$cmd"; sleep 1s; echo "exit";) | telnet 127.0.0.1 8081 2>&1 | tail -n +17 | grep -E -v "Connection closed|TelnetClient"
}

function change_hostname() {
    echo
    current_val=$(print_current_server_config "ServerName")
    echo "Current Server Hostname: $current_val"

    while true; do
        read -p "New Server Hostname: " hostname
        if [ -z "$hostname" ]; then
            break
        else
            update_server_config "ServerName" "$hostname" 
            break
        fi
    done
}

function change_password() {
    echo
    current_val=$(print_current_server_config "ServerPassword")
    echo "Current Password: $current_val"

    while true; do
        read -p "New Password: " password
        update_server_config "ServerPassword" "$password"
        break
    done
}

function change_region() {
    echo
    for i in "${!REGIONS[@]}"; do 
        echo "$((i+1)): ${REGIONS[i]}"
    done

    current_val=$(print_current_server_config "Region")
    echo
    echo "Current Region: $current_val"

    while true; do
        read -p "Select Region(1-${#REGIONS[@]}): " region_number

        if [ -z "$region_number" ]; then
            break
        elif [[ $region_number =~ ^[0-9]+$ ]] && [ $region_number -ge 1 ] && [ $region_number -le ${#REGIONS[@]} ]; then
            region="${REGIONS[$((region_number-1))]}"
            update_server_config "Region" "$region" 
            break
        fi
        echo "Invalid choice."
    done
}

function change_language() {
    echo
    for i in "${!LANGUAGES[@]}"; do 
        echo "$((i+1)): ${LANGUAGES[i]}"
    done

    current_val=$(print_current_server_config "Language")
    echo
    echo "Current Language: $current_val"

    while true; do
        read -p "Select Language(1-${#LANGUAGES[@]}): " language_number

        if [ -z "$language_number" ]; then
            break
        elif [[ $language_number =~ ^[0-9]+$ ]] && [ $language_number -ge 1 ] && [ $language_number -le ${#LANGUAGES[@]} ]; then
            language="${LANGUAGES[$((language_number-1))]}"
            update_server_config "Language" "$language" 
            break
        fi
        echo "Invalid choice."
    done
}

function change_visibility() {
    echo
    for i in "${!VISIBILITIES[@]}"; do 
        echo "$((i+0)): ${VISIBILITIES[i]}"
    done

    current_val=$(print_current_server_config "ServerVisibility")
    echo
    echo "Current Server Visibility: ${VISIBILITIES[$((current_val))]}"

    while true; do
        max_visibility_number=$((${#VISIBILITIES[@]} - 1))
        read -p "Select Server Visibility(0-${max_visibility_number}): " visibility_number

        if [ -z "$visibility_number" ]; then
            break
        elif [[ $visibility_number =~ ^[0-9]+$ ]] && [ $visibility_number -ge 0 ] && [ $visibility_number -le $max_visibility_number ]; then
            visibility=$visibility_number
            update_server_config "ServerVisibility" "$visibility" 
            break
        fi
        echo "Invalid choice."
    done
}

function change_difficulty() {
    echo
    for i in "${!DIFFICULTIES[@]}"; do 
        echo "$((i+0)): ${DIFFICULTIES[i]}"
    done

    current_val=$(print_current_server_config "GameDifficulty")
    echo
    echo "Current Game Difficulty: ${DIFFICULTIES[$((current_val))]}"

    while true; do
        max_difficulty_number=$((${#DIFFICULTIES[@]} - 1))
        read -p "Select Game Difficulty(0-${max_difficulty_number}): " difficulty_number

        if [ -z "$difficulty_number" ]; then
            break
        elif [[ $difficulty_number =~ ^[0-9]+$ ]] && [ $difficulty_number -ge 0 ] && [ $difficulty_number -le $max_difficulty_number ]; then
            difficulty=$difficulty_number
            update_server_config "GameDifficulty" "$difficulty" 
            break
        fi
        echo "Invalid choice."
    done
}

function change_map() {
    
    echo
    for i in "${!WORLDS[@]}"; do 
        echo "$((i+1)): ${WORLDS[i]}"
    done

    current_val=$(print_current_server_config "GameWorld")
    echo
    echo "Current World: $current_val"

    while true; do
        read -p "Select World(1-${#WORLDS[@]}): " worlds_number

        if [ -z "$worlds_number" ]; then
            break
        elif [[ $worlds_number =~ ^[0-9]+$ ]] && [ $worlds_number -ge 1 ] && [ $worlds_number -le ${#WORLDS[@]} ]; then
            world="${WORLDS[$((worlds_number-1))]}"

            echo 
            echo "Saved Game Names:"
            if [ -d  "$SDTD_SERVER_SAVE_DIR/$world/" ]; then
                find "$SDTD_SERVER_SAVE_DIR/$world/" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
            else
                echo "<No game found>"
            fi

            current_val=$(print_current_server_config "GameName")
            echo 
            echo "Current Game Name: $current_val"
            read -p "New Game Name: " game_name
            if [ -z "$game_name" ]; then
                break
            else
                update_server_config "GameWorld" "$world"
                update_server_config "GameName" "$game_name"
                break
            fi
        fi
        echo "Invalid choice."
    done
}

function add_admin() {
    echo

    while true; do
        read -p "Input Admin Player Name: " admin
        if [ -z "$admin" ]; then
            break
        else
            execute_command "admin add $admin 0"
            break
        fi
    done
}

function activate_control_panel() {
    local yes_no

    read -p "Activate Control Panel? (y/n): " yes_no

    if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
        update_server_config "WebDashboardEnabled" "true"
        update_server_config "WebDashboardPort" "8080"
    fi
}

function deactivate_control_panel() {
    local yes_no

    read -p "Deactivate Control Panel? (y/n): " yes_no

    if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
        update_server_config "WebDashboardEnabled" "false"
    fi
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
        echo "Restarting 7 Days to Die Server ..."
        systemctl restart 7dtd
    fi
}

function main_menu() {
    print_server_version

    while true; do
        echo
        echo "1. Activate Control Panel"
        echo "2. Deactivate Control Panel"
        echo "3. Add Admin User"
        echo "4. Change Server Hostname"
        echo "5. Change Password"
        echo "6. Change Region"
        echo "7. Change Language"
        echo "8. Change Server Visibility"
        echo "9. Change Game Difficulty"
        echo "10. Change Map"
        echo "q. Quit"
        read -p "Please enter your choice(1-10,q): " choice

        case $choice in
            1) activate_control_panel ;;
            2) deactivate_control_panel ;;
            3) add_admin ;;
            4) change_hostname ;;
            5) change_password ;;
            6) change_region ;;
            7) change_language ;;
            8) change_visibility ;;
            9) change_difficulty ;;
            10) change_map ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

echo "7 Days to Die Server Configutation Tool for Xserver VPS"
echo

check_xserver_vps
init
main_menu
