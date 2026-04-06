#!/bin/bash
# Copyright (C) 2026 shinya-blogger https://github.com/shinya-blogger
# Licensed under the MIT License. See https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE

declare -r SERVER_DIR="/home/steam/CoreKeeper"
declare -r SERVER_CONFIG_FILE="/home/steam/.config/unity3d/Pugstorm/Core Keeper/DedicatedServer/ServerConfig.json"

config_updated=false

function die() {
    local message="$1"
    echo "ERROR: $1"
    exit 1
}

function check_xserver_vps() {
    if [ ! -d "$SERVER_DIR" ]; then
        die "This server is not a Core Keeper Server by Xserver VPS."
    fi
}


function update_json_param() {
    local key="$1"
    local value="$2"
    local type="$3" # string or number

    if [ "$type" == "string" ]; then
        sed -i -E "s/(\"$key\": *)\"[^\"]*\"/\1\"$value\"/" "$SERVER_CONFIG_FILE"
    else
        sed -i -E "s/(\"$key\": *)[0-9-]+/\1$value/" "$SERVER_CONFIG_FILE"
    fi

    config_updated=true
}

function print_current_json_param() {
    local key="$1"
    local type="$2"

    if [ "$type" == "string" ]; then
        grep -E "\"$key\": *\"[^\"]*\"" "$SERVER_CONFIG_FILE" | sed -E "s/^.*\"$key\": *\"([^\"]*)\".*$/\1/"
    else
        grep -E "\"$key\": *[0-9-]+" "$SERVER_CONFIG_FILE" | sed -E "s/^.*\"$key\": *([0-9-]+).*$/\1/"
    fi
}

function change_max_players() {
    echo
    local current_val=$(print_current_json_param "maxNumberPlayers" "number")
    echo "現在の最大参加人数: $current_val"

    while true; do
        read -p "新しい最大参加人数を入力してください (1-100): " maxplayers
        if [ -z "$maxplayers" ]; then
            break
        elif [[ "$maxplayers" =~ ^[0-9]+$ ]] && [ "$maxplayers" -ge 1 ] && [ "$maxplayers" -le 100 ]; then
            update_json_param "maxNumberPlayers" "$maxplayers" "number"
            break
        fi
        echo "無効な値です。"
    done
}


function change_world_name() {
    echo
    local current_val=$(print_current_json_param "worldName" "string")
    echo "現在のワールド名: $current_val"

    read -p "新しいワールド名を入力してください: " worldname
    if [ -n "$worldname" ]; then
        update_json_param "worldName" "$worldname" "string"
    fi
}

function reset_game_id() {
    echo
    local current_val=$(print_current_json_param "gameId" "string")
    echo "現在のゲームID: $current_val"

    read -p "ゲームIDをリセットしますか？ (y/n): " confirm
    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
        # 除外文字: 0, Y, y, x, O と句読点
        local new_id=$(cat /dev/urandom | tr -dc 'A-NP-WX-Za-np-wz1-9' | head -c 28)
        update_json_param "gameId" "$new_id" "string"

        # /etc/motd 内の Game ID を更新
        if [ -f /etc/motd ]; then
            sed -i -E "s/(Game ID: +)[^ ]+/\1$new_id/" /etc/motd
        fi

        echo "新しいゲームID: $new_id"
    fi
}

function change_world_mode() {
    echo
    local current_val=$(print_current_json_param "worldMode" "number")
    local modes=("ノーマル" "ハード" "クリエイティブ" "カジュアル")
    local values=(0 1 2 4)
    
    echo "現在のワールドモード: $current_val"
    for i in "${!modes[@]}"; do
        echo "${values[i]}: ${modes[i]}"
    done

    while true; do
        read -p "新しいワールドモードを入力してください (0, 1, 2, 4): " choice
        if [ -z "$choice" ]; then
            break
        elif [[ "$choice" =~ ^[0124]$ ]]; then
            update_json_param "worldMode" "$choice" "number"
            break
        fi
        echo "無効な選択です。"
    done
}

function change_world_slot() {
    echo
    local current_val=$(print_current_json_param "world" "number")
    echo "現在のワールドスロット: $current_val"

    while true; do
        read -p "新しいワールドスロットを入力してください (0, 1, 2...): " slot
        if [ -z "$slot" ]; then
            break
        elif [[ "$slot" =~ ^[0-9]+$ ]]; then
            update_json_param "world" "$slot" "number"
            break
        fi
        echo "無効な値です。"
    done
}

function change_season() {
    echo
    local current_val=$(print_current_json_param "seasonOverride" "number")
    local seasons=("自動 (-1)" "無効 (0)" "イースター (1)" "ハロウィン (2)" "クリスマス (3)" "バレンタイン (4)" "アニバーサリー (5)" "桜 (6)" "旧正月 (7)")
    local values=(-1 0 1 2 3 4 5 6 7)

    echo "現在のシーズン設定: $current_val"
    for i in "${!seasons[@]}"; do
        echo "${values[i]}: ${seasons[i]}"
    done

    while true; do
        read -p "新しいシーズン値を入力してください (-1 ～ 7): " choice
        if [ -z "$choice" ]; then
            break
        elif [[ "$choice" =~ ^-?[0-7]$ ]]; then
            local valid=false
            for v in "${values[@]}"; do
                if [ "$choice" == "$v" ]; then
                    valid=true
                    break
                fi
            done
            if [ "$valid" == "true" ]; then
                update_json_param "seasonOverride" "$choice" "number"
                break
            fi
        fi
        echo "無効な選択です。"
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
    read -p "Core Keeper サーバーを再起動しますか？ (y/n): " yes_no
    if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
        echo "Core Keeper サーバーを再起動しています..."
        systemctl restart corekeeper
    fi
}

function main_menu() {
    echo "Core Keeper サーバー設定ツール for Xserver VPS"
    while true; do
        echo
        echo "1. 参加人数上限の変更"
        echo "2. ワールド名の変更"
        echo "3. ゲームIDのリセット"
        echo "4. ワールドモードの変更"
        echo "5. ワールドスロットの変更"
        echo "6. イベントシーズンの変更"
        echo "q. 終了"
        read -p "選択してください (1-6, q): " choice
        case $choice in
            1) change_max_players ;;
            2) change_world_name ;;
            3) reset_game_id ;;
            4) change_world_mode ;;
            5) change_world_slot ;;
            6) change_season ;;
            q) quit ;;
            *) echo "無効な選択です。" ;;
        esac
    done
}

check_xserver_vps
main_menu
