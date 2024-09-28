#!/bin/bash

# iniファイルのパス
INI_FILE="config.ini"

# iniファイルから値を読み込む関数
get_ini_value() {
    local key=$1
    local default_value=$2
    local value=$(grep -E "^$key[[:space:]]*=" "$INI_FILE" | sed -E "s/^$key[[:space:]]*=[[:space:]]*(.*)/\1/")
    if [[ -z "$value" ]]; then
        echo "$default_value"  # 値がなければデフォルト値を使用
    else
        echo "$value"  # 値があればその値を返す
    fi
}

# iniファイルのキーと値を更新する関数 (Sanitized)
update_ini() {
    local key=$1
    local value=$2

    # Sanitize the value: remove unwanted characters or sequences
    value=$(echo "$value" | sed 's/[^a-zA-Z0-9_.-]//g')  # Remove any non-alphanumeric or special characters

    # Ensure that value is not empty and valid before writing to the ini file
    if [[ -n "$value" ]]; then
        # If key exists, update it. If not, append it to the config file.
        if grep -q "^$key[[:space:]]*=" "$INI_FILE"; then
            sed -i "s/^$key[[:space:]]*=.*/$key = $value/" "$INI_FILE"
        else
            echo "$key = $value" >> "$INI_FILE"
        fi
    else
        dialog --msgbox "無効な入力です。再度入力してください。" 6 40
    fi
}

# 入力値が空でないか、かつ不正な文字がないか確認する関数
get_valid_input() {
    local prompt_message=$1
    local current_value=$2
    local result=""
    
    while true; do
        result=$(dialog --inputbox "$prompt_message" 8 50 "$current_value" 2>&1 >/dev/tty)
        
        if [[ -z "$result" ]]; then
            dialog --msgbox "値を入力してください！空の値は許可されていません。" 6 40
        elif [[ "$result" =~ [^a-zA-Z0-9_.-] ]]; then
            dialog --msgbox "不正な文字が含まれています。もう一度入力してください。" 6 40
        else
            echo "$result"
            break
        fi
    done
}

# radiolistの選択が空でないか確認する関数
get_valid_radiolist() {
    local prompt_message=$1
    local options=$2
    local result=""
    
    while [[ -z "$result" ]]; do
        result=$(dialog --radiolist "$prompt_message" 10 50 2 $options 2>&1 >/dev/tty)
        if [[ -z "$result" ]]; then
            dialog --msgbox "有効な選択肢を選んでください。" 6 40
        fi
    done
    echo "$result"
}

# メインメニュー
show_menu() {
    while true; do
        CHOICE=$(dialog --clear --colors --title "\Zb\Z5JOX PRIVATE\Zn" \
            --ok-label "次へ" \
            --cancel-label "取り消し" \
            --menu "機能を選択してください" 15 50 6 \
            "1" "Aimbot設定" \
            "2" "Glow設定" \
            "3" "アンチリコイル設定" \
            "4" "トリガーボット設定" \
            "5" "各機能のオンオフ" \
            "6" "メニューだけ閉じる" 2>&1 >/dev/tty)

        case $CHOICE in
            1) show_aimbot_menu ;;
            2) show_sense_menu ;;
            3) show_norecoil_menu ;;
            4) show_triggerbot_menu ;;
            5) show_feature_toggles ;;
            6) break ;;
        esac
    done
}

# Aimbotのサブメニュー
show_aimbot_menu() {
    # デフォルト値またはiniファイルからの値を取得
    AIMBOT_SMOOTH=$(get_ini_value "AIMBOT_SMOOTH" "100")
    AIMBOT_FOV=$(get_ini_value "AIMBOT_FOV" "90")
    AIMBOT_MAX_DISTANCE=$(get_ini_value "AIMBOT_MAX_DISTANCE" "500")
    AIMBOT_MIN_DISTANCE=$(get_ini_value "AIMBOT_MIN_DISTANCE" "0")

    AIMBOT_SMOOTH=$(get_valid_input "エイムボットの滑らかさ（0-1500）小さいほど強い" "$AIMBOT_SMOOTH")
    AIMBOT_FOV=$(get_valid_input "Aimbot FOV" "$AIMBOT_FOV")
    AIMBOT_MAX_DISTANCE=$(get_valid_input "エイムボットの最大距離" "$AIMBOT_MAX_DISTANCE")
    AIMBOT_MIN_DISTANCE=$(get_valid_input "エイムボットの最小距離" "$AIMBOT_MIN_DISTANCE")

    AIMBOT_ACTIVATED_BY_ATTACK=$(get_valid_radiolist "発射時にエイムボットを発動させますか？" \
        "YES 発射時にエイムボットを有効にする ON NO 発射時には無効にする OFF")

    AIMBOT_ACTIVATED_BY_ADS=$(get_valid_radiolist "ADS（Aim Down Sights）時にエイムボットを発動させますか？" \
        "YES ADS時にエイムボットを有効にする ON NO ADS時には無効にする OFF")

    # iniファイルに保存
    update_ini "AIMBOT_SMOOTH" "$AIMBOT_SMOOTH"
    update_ini "AIMBOT_FOV" "$AIMBOT_FOV"
    update_ini "AIMBOT_MAX_DISTANCE" "$AIMBOT_MAX_DISTANCE"
    update_ini "AIMBOT_MIN_DISTANCE" "$AIMBOT_MIN_DISTANCE"
    update_ini "AIMBOT_ACTIVATED_BY_ATTACK" "$AIMBOT_ACTIVATED_BY_ATTACK"
    update_ini "AIMBOT_ACTIVATED_BY_ADS" "$AIMBOT_ACTIVATED_BY_ADS"
}

# Glowのサブメニュー
show_sense_menu() {
    SENSE_MAXRANGE=$(get_ini_value "SENSE_MAXRANGE" "500")
    Red=$(get_ini_value "Red" "255")
    Green=$(get_ini_value "Green" "0")
    Blue=$(get_ini_value "Blue" "0")

    SENSE_MAXRANGE=$(get_valid_input "Glowの最大距離" "$SENSE_MAXRANGE")
    Red=$(get_valid_input "Red (0-255)" "$Red")
    Green=$(get_valid_input "Green (0-255)" "$Green")
    Blue=$(get_valid_input "Blue (0-255)" "$Blue")

    update_ini "SENSE_MAXRANGE" "$SENSE_MAXRANGE"
    update_ini "Red" "$Red"
    update_ini "Green" "$Green"
    update_ini "Blue" "$Blue"
}

# No Recoilのサブメニュー
show_norecoil_menu() {
    NORECOIL_PITCH_REDUCTION=$(get_ini_value "NORECOIL_PITCH_REDUCTION" "50")
    NORECOIL_YAW_REDUCTION=$(get_ini_value "NORECOIL_YAW_REDUCTION" "50")

    NORECOIL_PITCH_REDUCTION=$(get_valid_input "横のリコイル" "$NORECOIL_PITCH_REDUCTION")
    NORECOIL_YAW_REDUCTION=$(get_valid_input "縦のリコイル" "$NORECOIL_YAW_REDUCTION")

    update_ini "NORECOIL_PITCH_REDUCTION" "$NORECOIL_PITCH_REDUCTION"
    update_ini "NORECOIL_YAW_REDUCTION" "$NORECOIL_YAW_REDUCTION"
}

# Triggerbotのサブメニュー
show_triggerbot_menu() {
    TRIGGERBOT_ZOOMED_RANGE=$(get_ini_value "TRIGGERBOT_ZOOMED_RANGE" "300")
    TRIGGERBOT_HIPFIRE_RANGE=$(get_ini_value "TRIGGERBOT_HIPFIRE_RANGE" "200")

    TRIGGERBOT_ZOOMED_RANGE=$(get_valid_input "ADS時のトリガー距離" "$TRIGGERBOT_ZOOMED_RANGE")
    TRIGGERBOT_HIPFIRE_RANGE=$(get_valid_input "腰うちのトリガー距離" "$TRIGGERBOT_HIPFIRE_RANGE")

    update_ini "TRIGGERBOT_ZOOMED_RANGE" "$TRIGGERBOT_ZOOMED_RANGE"
    update_ini "TRIGGERBOT_HIPFIRE_RANGE" "$TRIGGERBOT_HIPFIRE_RANGE"
}

# Feature Togglesメニュー
show_feature_toggles() {
    # Get current values from config or set to default "NO"
    FEATURE_AIMBOT_ON=$(get_ini_value "FEATURE_AIMBOT_ON" "NO")
    FEATURE_SENSE_ON=$(get_ini_value "FEATURE_SENSE_ON" "NO")
    FEATURE_ITEM_GLOW_ON=$(get_ini_value "FEATURE_ITEM_GLOW_ON" "NO")
    FEATURE_NORECOIL_ON=$(get_ini_value "FEATURE_NORECOIL_ON" "NO")
    FEATURE_TRIGGERBOT_ON=$(get_ini_value "FEATURE_TRIGGERBOT_ON" "NO")
    FEATURE_SPECTATOR_ON=$(get_ini_value "FEATURE_SPECTATOR_ON" "NO")
    FEATURE_SKINCHANGER_ON=$(get_ini_value "FEATURE_SKINCHANGER_ON" "NO")
    FEATURE_SUPER_GLIDE_ON=$(get_ini_value "FEATURE_SUPER_GLIDE_ON" "NO")

    # Convert current values to dialog-friendly format (ON or OFF)
    AIMBOT_STATUS=$( [[ "$FEATURE_AIMBOT_ON" == "YES" ]] && echo "ON" || echo "OFF" )
    SENSE_STATUS=$( [[ "$FEATURE_SENSE_ON" == "YES" ]] && echo "ON" || echo "OFF" )
    ITEM_GLOW_STATUS=$( [[ "$FEATURE_ITEM_GLOW_ON" == "YES" ]] && echo "ON" || echo "OFF" )
    NORECOIL_STATUS=$( [[ "$FEATURE_NORECOIL_ON" == "YES" ]] && echo "ON" || echo "OFF" )
    TRIGGERBOT_STATUS=$( [[ "$FEATURE_TRIGGERBOT_ON" == "YES" ]] && echo "ON" || echo "OFF" )
    SPECTATOR_STATUS=$( [[ "$FEATURE_SPECTATOR_ON" == "YES" ]] && echo "ON" || echo "OFF" )
    SKINCHANGER_STATUS=$( [[ "$FEATURE_SKINCHANGER_ON" == "YES" ]] && echo "ON" || echo "OFF" )
    SUPER_GLIDE_STATUS=$( [[ "$FEATURE_SUPER_GLIDE_ON" == "YES" ]] && echo "ON" || echo "OFF" )

    # Check box menu to toggle features
    choices=$(dialog --checklist "Toggle Features On/Off" 20 60 10 \
        1 "Aimbot" "$AIMBOT_STATUS" \
        2 "Glow" "$SENSE_STATUS" \
        3 "Item Glow" "$ITEM_GLOW_STATUS" \
        4 "No Recoil" "$NORECOIL_STATUS" \
        5 "Triggerbot" "$TRIGGERBOT_STATUS" \
        6 "Spectator" "$SPECTATOR_STATUS" \
        7 "Skin Changer" "$SKINCHANGER_STATUS" \
        8 "Super Glide" "$SUPER_GLIDE_STATUS" 2>&1 >/dev/tty)

    # Reset all features to "NO"
    update_ini "FEATURE_AIMBOT_ON" "NO"
    update_ini "FEATURE_SENSE_ON" "NO"
    update_ini "FEATURE_ITEM_GLOW_ON" "NO"
    update_ini "FEATURE_NORECOIL_ON" "NO"
    update_ini "FEATURE_TRIGGERBOT_ON" "NO"
    update_ini "FEATURE_SPECTATOR_ON" "NO"
    update_ini "FEATURE_SKINCHANGER_ON" "NO"
    update_ini "FEATURE_SUPER_GLIDE_ON" "NO"

    # Process user selections
    for choice in $choices; do
        case $choice in
            1) update_ini "FEATURE_AIMBOT_ON" "YES" ;;
            2) update_ini "FEATURE_SENSE_ON" "YES" ;;
            3) update_ini "FEATURE_ITEM_GLOW_ON" "YES" ;;
            4) update_ini "FEATURE_NORECOIL_ON" "YES" ;;
            5) update_ini "FEATURE_TRIGGERBOT_ON" "YES" ;;
            6) update_ini "FEATURE_SPECTATOR_ON" "YES" ;;
            7) update_ini "FEATURE_SKINCHANGER_ON" "YES" ;;
            8) update_ini "FEATURE_SUPER_GLIDE_ON" "YES" ;;
        esac
    done
}


# 設定ファイルから現在の設定を読み込む関数
load_config() {
    if [ -f "$INI_FILE" ]; then
        source "$INI_FILE"
    else
        echo "Config file not found!"
        exit 1
    fi
}

# メイン実行
load_config
show_menu
