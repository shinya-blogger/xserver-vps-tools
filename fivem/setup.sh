#!/bin/bash
# Copyright (C) 2025 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

# --- Global Variables ---
declare -r FIVEM_SERVER_DIR="/home/fivem/server"
declare -r FIVEM_CONSOLE_LOG="$FIVEM_SERVER_DIR/console.log"
declare -r FIVEM_SERVICE_NAME="fivem-server"

# --- Utility Functions ---

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function install_package() {
    local pkg=$1
    if ! dpkg -l | grep -q "$pkg"; then
        echo "Installing required package: $pkg..."
        DEBIAN_FRONTEND=noninteractive apt-get -qq update > /dev/null && apt-get -qq install -y "$pkg" > /dev/null
        if [ $? -ne 0 ]; then
            die "Failed to install package: $pkg. Please install it manually."
        fi
        echo "Installation of $pkg completed."
    fi
}

function check_fivem_environment() {
    if [ ! -d "$FIVEM_SERVER_DIR" ]; then
        die "FiveM server directory not found at $FIVEM_SERVER_DIR."
    fi
    if [ ! -x "$FIVEM_SERVER_DIR/run.sh" ]; then
        echo "Warning: run.sh not found or not executable in $FIVEM_SERVER_DIR."
    fi
    if ! id "fivem" &>/dev/null; then
        echo "Warning: User 'fivem' does not exist."
    fi
}

# --- Feature Functions ---

function check_pin() {
    echo
    echo "Checking for the latest PIN..."
    if [ ! -f "$FIVEM_CONSOLE_LOG" ]; then
        echo "Console log file not found: $FIVEM_CONSOLE_LOG"
        return
    fi

    local pin_info
    pin_info=$(grep PIN "$FIVEM_CONSOLE_LOG" | tail -1)

    if [ -n "$pin_info" ]; then
        echo "--- Found PIN ---"
        echo "$pin_info"
        echo "-----------------"
    else
        echo "No PIN information found in the log."
    fi
}

function update_server() {
    install_package "libxml2-utils"

    echo
    echo "Checking for FiveM server updates..."

    local artifacts_url="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
    
    local latest_version
    latest_version=$(curl -s "$artifacts_url" | xmllint --html --xpath "string(//a[contains(text(), 'LATEST RECOMMENDED')])" - 2>/dev/null | grep -oP '\(\K\d+(?=\))')
    
    if [ -z "$latest_version" ]; then
        echo "Could not determine the latest recommended version. Please check your network or artifact page structure."
        return
    fi

    local current_version="N/A"
    if [ -x "$FIVEM_SERVER_DIR/run.sh" ]; then
        current_version=$(cd "$FIVEM_SERVER_DIR" && ./run.sh --version | head -n 1 | grep -oP 'v\d+\.\d+\.\d+\.\K\d+')
    fi

    echo "Current installed version: $current_version"
    echo "Latest recommended version: $latest_version"

    if [ "$latest_version" == "$current_version" ]; then
        echo "Your FiveM server is already up to date."
        return
    fi

    local yes_no
    read -p "Do you want to update to version $latest_version? (y/n): " yes_no

    if [[ "$yes_no" != "y" ]] && [[ "$yes_no" != "Y" ]]; then
        echo "Update cancelled."
        return
    fi
    
    # --- 修正点: アップデート承認後にサーバー状態を確認 ---
    local server_was_running=false
    if systemctl is-active --quiet "$FIVEM_SERVICE_NAME"; then
        server_was_running=true
        echo
        local stop_confirm
        read -p "The FiveM server is running. It must be stopped to continue the update. Stop it now? (y/n): " stop_confirm
        if [[ "$stop_confirm" != "y" ]] && [[ "$stop_confirm" != "Y" ]]; then
            echo "Update cancelled because the server was not stopped."
            return
        fi
        echo "Stopping FiveM server..."
        systemctl stop "$FIVEM_SERVICE_NAME"
    fi
    # --- 修正ここまで ---

    echo "Finding exact download URL ..."
    local download_path
    download_path=$(curl -s "$artifacts_url" | xmllint --html --xpath "string(//a[contains(text(), 'LATEST RECOMMENDED')]/@href)" - 2>/dev/null)

    if [ -z "$download_path" ]; then
        echo "Failed to find the download path. The artifact page structure might have changed."
        # もしサーバーを停止させていたら、再起動して終了する
        if [ "$server_was_running" == "true" ]; then
            echo "Restarting the FiveM server..."
            systemctl start "$FIVEM_SERVICE_NAME"
        fi
        return 1
    fi
    
    download_path=${download_path#./}
    local download_url="${artifacts_url}${download_path}"

    local tmp_file
    tmp_file=$(mktemp /tmp/fivem-update.XXXXXXXXXX.tar.xz)
    if [ ! -f "$tmp_file" ]; then
        echo "ERROR: Failed to create a temporary file."
        return 1
    fi
    
    trap 'rm -f "$tmp_file"' EXIT

    echo "Starting update..."
    echo "Downloading from: $download_url"
    
    wget -qO "$tmp_file" "$download_url"
    if [ $? -ne 0 ]; then
        echo "Failed to download the update file. Please check the URL and your network."
        return 1
    fi
    
    echo "Removing old core files before extraction..."
    rm -rf "$FIVEM_SERVER_DIR/alpine"
    rm -f "$FIVEM_SERVER_DIR/run.sh"

    echo "Extracting files to $FIVEM_SERVER_DIR..."
    tar -xf "$tmp_file" -C "$FIVEM_SERVER_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to extract files."
        return 1
    fi
    
    echo "Setting permissions..."
    chown -R fivem:fivem "$FIVEM_SERVER_DIR"

    echo "Update completed successfully."
    if [ "$server_was_running" == "true" ]; then
        echo "Restarting the FiveM server automatically..."
        if systemctl start "$FIVEM_SERVICE_NAME"; then
            echo "Server started successfully."
        else
            echo "ERROR: Failed to restart the server. Please start it manually using 'systemctl start $FIVEM_SERVICE_NAME'."
        fi
    else
        echo "The server was not running before the update, so it has not been started automatically."
    fi
}

function restart_server() {
    echo
    local yes_no
    read -p "Are you sure you want to restart the FiveM server? (y/n): " yes_no

    if [[ "$yes_no" == "y" ]] || [[ "$yes_no" == "Y" ]]; then
        echo "Restarting FiveM server ($FIVEM_SERVICE_NAME)..."
        if systemctl restart "$FIVEM_SERVICE_NAME"; then
            echo "Server restart command issued successfully."
        else
            echo "Failed to restart the server. Please check the service name ($FIVEM_SERVICE_NAME) and its status."
        fi
    fi
}

function quit() {
    echo "Exiting the script."
    exit 0
}

# --- Main Menu ---

function main_menu() {
    while true; do
        echo
        echo "--- FiveM Server Management Menu ---"
        echo "1. Check Server PIN"
        echo "2. Update Server"
        echo "3. Restart Server"
        echo "q. Quit"
        read -p "Please enter your choice (1-3, q): " choice

        case $choice in
            1) check_pin ;;
            2) update_server ;;
            3) restart_server ;;
            q) quit ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}


# --- Script Execution ---

echo "FiveM Server Management Tool for Xserver VPS"
echo

check_fivem_environment
main_menu