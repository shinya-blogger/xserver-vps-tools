#!/bin/bash
# Copyright (C) 2025-2026 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

# --- Global Variables ---
declare -r TMODLOADER_URL="https://github.com/tModLoader/tModLoader/releases/latest/download/tModLoader.zip"
declare -r TMODLOADER_BASE_DIR="/opt/terraria/tModLoader"
declare -r TMODLOADER_SERVER_DIR="$TMODLOADER_BASE_DIR/server"
declare -r TMODLOADER_CONF_DIR="$TMODLOADER_BASE_DIR/conf"
declare -r TMODLOADER_SAVES_DIR="$TMODLOADER_BASE_DIR/saves"
declare -r TMODLOADER_WORLDS_DIR="$TMODLOADER_SAVES_DIR/Worlds"
declare -r TMODLOADER_CONF_FILE="$TMODLOADER_CONF_DIR/serverconfig.txt"
declare -r TERRARIA_USER="terraria"
declare -r VANILLA_SERVER_SERVICE="terraria_server"
declare -r VANILLA_AUTOSAVE_SERVICE="terraria_autosave"

config_updated=false

# --- Utility Functions ---

function die() {
    echo "ERROR: $1"
    exit 1
}

function install_package() {
    local pkg=$1
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "Installing required package: $pkg..."
        DEBIAN_FRONTEND=noninteractive apt-get -qq update > /dev/null && apt-get -qq install -y "$pkg" > /dev/null
        if [ $? -ne 0 ]; then
            die "Failed to install package: $pkg. Please install it manually."
        fi
        echo "Installation of $pkg completed."
    fi
}

function is_tmodloader_installed() {
    [ -f "$TMODLOADER_SERVER_DIR/start-tModLoaderServer.sh" ]
}

function get_tmodloader_version() {
    local deps_file="$TMODLOADER_SERVER_DIR/tModLoader.deps.json"
    if ! [ -f "$deps_file" ]; then
        echo "unknown"
        return
    fi
    grep -o '"tModLoader/[^"]*"' "$deps_file" | head -1 | grep -o '[0-9.]*'
}

function get_serverconfig() {
    local key="$1"
    grep "^$key=" "$TMODLOADER_CONF_FILE" 2>/dev/null | tail -1 | cut -d= -f2-
}

function update_serverconfig() {
    local key="$1"
    local value="$2"
    if grep -q "^$key=" "$TMODLOADER_CONF_FILE"; then
        sed -i "s|^$key=.*|$key=$value|" "$TMODLOADER_CONF_FILE"
    else
        echo "$key=$value" >> "$TMODLOADER_CONF_FILE"
    fi
    config_updated=true
}

# --- Core Helpers ---

function _download_and_extract() {
    install_package "unzip"

    local tmp_file
    tmp_file=$(mktemp /tmp/tmodloader.XXXXXXXXXX.zip)
    trap 'rm -f "$tmp_file"' EXIT

    echo "Downloading tModLoader from $TMODLOADER_URL..."
    wget -qO "$tmp_file" "$TMODLOADER_URL" || die "Failed to download tModLoader."

    echo "Extracting tModLoader..."
    rm -rf "$TMODLOADER_SERVER_DIR"
    mkdir -p "$TMODLOADER_SERVER_DIR"
    unzip -q "$tmp_file" -d "$TMODLOADER_SERVER_DIR" || die "Failed to extract tModLoader."

    echo "Setting execute permissions on shell scripts..."
    find "$TMODLOADER_SERVER_DIR" -name "*.sh" -exec chmod +x {} \;
}

function _setup_systemd() {
    cat > /etc/systemd/system/tmodloader_server.service <<'EOF'
[Unit]
Description=tModLoader Server
After=network.target

[Service]
Type=forking
User=terraria
Group=terraria
ProtectSystem=full
ProtectHome=yes
ExecStart=/usr/bin/screen -AmdS terraria /opt/terraria/tModLoader/server/./start-tModLoaderServer.sh -nosteam -config /opt/terraria/tModLoader/conf/serverconfig.txt -tmlsavedirectory /opt/terraria/tModLoader/saves
ExecStop=/usr/bin/screen -p 0 -S terraria -X eval 'stuff "exit"\015'

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/tmodloader_autosave.service <<'EOF'
[Unit]
Description=Save tModLoader map data.
Requisite=tmodloader_server.service

[Service]
User=terraria
Group=terraria
ProtectSystem=full
ProtectHome=yes
Type=oneshot
ExecStart=/bin/screen -p 0 -S terraria -X eval 'stuff "save"\015'
EOF

    cat > /etc/systemd/system/tmodloader_autosave.timer <<'EOF'
[Unit]
Description=Save tModLoader map data every 3 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=3min
Persistent=yes

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable tmodloader_server.service
    systemctl enable tmodloader_autosave.timer
}

# --- Feature Functions ---

function install_tmodloader() {
    echo
    if is_tmodloader_installed; then
        echo "tModLoader is already installed at $TMODLOADER_SERVER_DIR."
        return
    fi

    local yes_no
    read -p "Install tModLoader? This will stop the vanilla Terraria server. (y/n): " yes_no
    if [[ "$yes_no" != "y" ]] && [[ "$yes_no" != "Y" ]]; then
        echo "Installation cancelled."
        return
    fi

    echo "Stopping and disabling vanilla Terraria services..."
    systemctl stop "$VANILLA_AUTOSAVE_SERVICE" 2>/dev/null || true
    systemctl stop "$VANILLA_SERVER_SERVICE" 2>/dev/null || true
    systemctl disable "$VANILLA_AUTOSAVE_SERVICE" 2>/dev/null || true
    systemctl disable "$VANILLA_SERVER_SERVICE" 2>/dev/null || true

    mkdir -p "$TMODLOADER_CONF_DIR"
    mkdir -p "$TMODLOADER_SAVES_DIR"

    _download_and_extract

    if [ ! -f "$TMODLOADER_SERVER_DIR/serverconfig.txt" ]; then
        die "serverconfig.txt not found in the extracted archive."
    fi

    echo "Copying and configuring serverconfig.txt..."
    cp "$TMODLOADER_SERVER_DIR/serverconfig.txt" "$TMODLOADER_CONF_FILE"
    {
        echo "difficulty=0"
        echo "autocreate=1"
    } >> "$TMODLOADER_CONF_FILE"

    echo "Setting ownership to $TERRARIA_USER..."
    chown -R "$TERRARIA_USER:$TERRARIA_USER" "$TMODLOADER_BASE_DIR"

    echo "Creating systemd service files..."
    _setup_systemd

    echo "Starting tModLoader server..."
    if systemctl start tmodloader_server.service; then
        echo "tModLoader server started successfully."
    else
        die "Failed to start tModLoader server. Check: journalctl -u tmodloader_server"
    fi
    systemctl start tmodloader_autosave.timer

    echo
    echo "tModLoader installation completed successfully."
}

function update_tmodloader() {
    echo
    if ! is_tmodloader_installed; then
        echo "tModLoader is not installed."
        return
    fi

    local yes_no
    read -p "Update tModLoader? The server will be stopped during the update. (y/n): " yes_no
    if [[ "$yes_no" != "y" ]] && [[ "$yes_no" != "Y" ]]; then
        echo "Update cancelled."
        return
    fi

    echo "Stopping tModLoader server..."
    systemctl stop tmodloader_autosave.timer 2>/dev/null || true
    systemctl stop tmodloader_server.service 2>/dev/null || true

    _download_and_extract

    if [ ! -f "$TMODLOADER_CONF_FILE" ] && [ -f "$TMODLOADER_SERVER_DIR/serverconfig.txt" ]; then
        echo "Copying serverconfig.txt (first time)..."
        cp "$TMODLOADER_SERVER_DIR/serverconfig.txt" "$TMODLOADER_CONF_FILE"
    fi

    echo "Setting ownership to $TERRARIA_USER..."
    chown -R "$TERRARIA_USER:$TERRARIA_USER" "$TMODLOADER_BASE_DIR"

    echo "Starting tModLoader server..."
    if systemctl start tmodloader_server.service; then
        echo "tModLoader server started successfully."
    else
        die "Failed to start tModLoader server. Check: journalctl -u tmodloader_server"
    fi
    systemctl start tmodloader_autosave.timer

    echo
    echo "tModLoader update completed successfully."
}

function uninstall_tmodloader() {
    echo
    if ! is_tmodloader_installed; then
        echo "tModLoader does not appear to be installed."
        return
    fi

    local yes_no
    read -p "Uninstall tModLoader and restore the vanilla Terraria server? (y/n): " yes_no
    if [[ "$yes_no" != "y" ]] && [[ "$yes_no" != "Y" ]]; then
        echo "Uninstallation cancelled."
        return
    fi

    echo "Stopping tModLoader services..."
    systemctl stop tmodloader_autosave.timer 2>/dev/null || true
    systemctl stop tmodloader_autosave.service 2>/dev/null || true
    systemctl stop tmodloader_server.service 2>/dev/null || true

    echo "Disabling and removing tModLoader systemd files..."
    systemctl disable tmodloader_autosave.timer 2>/dev/null || true
    systemctl disable tmodloader_server.service 2>/dev/null || true
    rm -f /etc/systemd/system/tmodloader_server.service
    rm -f /etc/systemd/system/tmodloader_autosave.service
    rm -f /etc/systemd/system/tmodloader_autosave.timer
    systemctl daemon-reload

    echo "Removing tModLoader server files (saves and conf are preserved)..."
    rm -rf "$TMODLOADER_SERVER_DIR"

    echo "Restoring vanilla Terraria services..."
    systemctl enable "$VANILLA_SERVER_SERVICE" 2>/dev/null || true
    systemctl enable "$VANILLA_AUTOSAVE_SERVICE" 2>/dev/null || true
    systemctl start "$VANILLA_SERVER_SERVICE" 2>/dev/null || true
    systemctl start "$VANILLA_AUTOSAVE_SERVICE" 2>/dev/null || true

    echo
    echo "tModLoader has been uninstalled. Vanilla Terraria server restored."
}

function change_world() {
    echo

    local worlds=()
    while IFS= read -r line; do
        [ -n "$line" ] && worlds+=("$line")
    done < <(find "$TMODLOADER_WORLDS_DIR" -maxdepth 1 -type f -name "*.wld" 2>/dev/null | sort)

    if [ "${#worlds[@]}" -eq 0 ]; then
        echo "No world files found in $TMODLOADER_WORLDS_DIR"
        return
    fi

    echo "Available Worlds:"
    local i=1
    for world in "${worlds[@]}"; do
        echo "$i. $(basename "$world")"
        ((i++))
    done

    echo
    local current_world
    current_world=$(get_serverconfig "world")
    echo "Current World: ${current_world:-<not set>}"

    while true; do
        read -p "Select World Number (Enter to cancel): " selection
        if [ -z "$selection" ]; then
            break
        elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#worlds[@]}" ]; then
            local selected_world="${worlds[$((selection-1))]}"
            update_serverconfig "world" "$selected_world"
            echo "World set to: $selected_world"
            break
        else
            echo "Invalid selection. Please enter a number between 1 and ${#worlds[@]}."
        fi
    done
}

function restart_server() {
    local yes_no
    read -p "Restart tModLoader Server? (y/n): " yes_no
    if [[ "$yes_no" == "y" ]] || [[ "$yes_no" == "Y" ]]; then
        echo "Restarting tModLoader server..."
        systemctl restart tmodloader_server.service
    fi
}

function quit() {
    echo
    if [ "$config_updated" == "true" ]; then
        restart_server
    fi
    exit 0
}

# --- Main Menu ---

function main_menu() {
    while true; do
        echo
        if is_tmodloader_installed; then
            echo "--- Terraria Server Management Menu ---"
            echo "1. Update tModLoader"
            echo "2. Uninstall tModLoader"
            echo "3. Change World"
            echo "q. Quit"
            read -p "Please enter your choice (1-3, q): " choice
            case $choice in
                1) update_tmodloader ;;
                2) uninstall_tmodloader ;;
                3) change_world ;;
                q) quit ;;
                *) echo "Invalid choice. Please try again." ;;
            esac
        else
            echo "--- Terraria Server Management Menu ---"
            echo "1. Install tModLoader"
            echo "q. Quit"
            read -p "Please enter your choice (1, q): " choice
            case $choice in
                1) install_tmodloader ;;
                q) quit ;;
                *) echo "Invalid choice. Please try again." ;;
            esac
        fi
    done
}

# --- Script Execution ---

if [ "$(id -u)" -ne 0 ]; then
    die "This script must be run as root."
fi

echo "Terraria Server Management Tool for Xserver VPS"

if is_tmodloader_installed; then
    version=$(get_tmodloader_version)
    echo "tModLoader version: $version"
    echo
fi

main_menu
