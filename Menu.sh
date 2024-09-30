#!/bin/bash
exec 2>/dev/null  # スクリプト全体のエラーメッセージを無視

# スクリプトの内容


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
        zenity --error --text="無効な入力です。再度入力してください。"
    fi
}

# 入力値が空でないか、かつ不正な文字がないか確認する関数
get_valid_input() {
    local prompt_message=$1
    local current_value=$2
    local result=""
    
    while true; do
        result=$(zenity --entry --title="入力" --text="$prompt_message" --entry-text="$current_value")
        
        if [[ -z "$result" ]]; then
            zenity --error --text="値を入力してください！空の値は許可されていません。"
        elif [[ "$result" =~ [^a-zA-Z0-9_.-] ]]; then
            zenity --error --text="不正な文字が含まれています。もう一度入力してください。"
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
        result=$(zenity --list --radiolist --title="選択" --text="$prompt_message" --column="選択" --column="オプション" \
            TRUE "ON" FALSE "OFF")
        if [[ -z "$result" ]]; then
            zenity --error --text="有効な選択肢を選んでください。"
        fi
    done
    echo "$result"
}

# メインメニュー
show_menu() {
    while true; do
        CHOICE=$(zenity --list --title="JOX PRIVATE" --text="機能を選択してください" \
            --column="番号" --column="機能" \
            --width=600 --height=600 \
            --hide-header \
            "1" "Aimbot設定" \
            "2" "Glow設定" \
            "3" "アンチリコイル設定" \
            "4" "トリガーボット設定" \
            "5" "各機能のオンオフ" \
            "6" "メニューだけ閉じる")

        # CHOICEに値が入っていない場合、キャンセルと同様の扱いをする
        if [[ -z "$CHOICE" ]]; then
            break
        fi

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
    while true; do
        CHOICE=$(zenity --list --title="Aimbot設定メニュー" --text="設定項目を選択してください" \
            --column="番号" --column="設定項目" \
            --width=600 --height=600 \
            --hide-header \
            "1" "スコープ覗いてる時のエイムボットの滑らかさ" \
            "2" "腰だめ射撃時のエイムボットの滑らかさ" \
            "3" "Aimbot FOV（吸い付く範囲）" \
            "4" "エイムボットの最大距離" \
            "5" "エイムボットの最小距離" \
            "6" "発射時にエイムボットを発動するかどうか" \
            "7" "ADS時にエイムボットを発動するかどうか" \
            "8" "メインメニューに戻る")

        # CHOICEが空の場合はメインメニューに戻る
        if [[ -z "$CHOICE" ]]; then
            break
        fi

        case $CHOICE in
            1) change_aimbot_smooth ;;
            2) change_hipfire_aimbot_smooth ;;
            3) change_aimbot_fov ;;
            4) change_aimbot_max_distance ;;
            5) change_aimbot_min_distance ;;
            6) change_aimbot_activated_by_attack ;;
            7) change_aimbot_activated_by_ads ;;
            8) break ;;
        esac
    done
}

# 個別設定変更の関数
change_aimbot_smooth() {
    AIMBOT_SMOOTH=$(get_ini_value "AIMBOT_SMOOTH" "100")
    AIMBOT_SMOOTH=$(get_valid_input "エイムボットの滑らかさ（0-1500）小さいほど強い" "$AIMBOT_SMOOTH")
    update_ini "AIMBOT_SMOOTH" "$AIMBOT_SMOOTH"
}

# 新しく追加された HIPFIRE_AIMBOT_SMOOTH の設定変更関数
change_hipfire_aimbot_smooth() {
    HIPFIRE_AIMBOT_SMOOTH=$(get_ini_value "HIPFIRE_AIMBOT_SMOOTH" "100")
    HIPFIRE_AIMBOT_SMOOTH=$(get_valid_input "腰だめ射撃時のエイムボットの滑らかさ（0-1500）" "$HIPFIRE_AIMBOT_SMOOTH")
    update_ini "HIPFIRE_AIMBOT_SMOOTH" "$HIPFIRE_AIMBOT_SMOOTH"
}

change_aimbot_fov() {
    AIMBOT_FOV=$(get_ini_value "AIMBOT_FOV" "90")
    AIMBOT_FOV=$(get_valid_input "Aimbot FOV" "$AIMBOT_FOV")
    update_ini "AIMBOT_FOV" "$AIMBOT_FOV"
}

change_aimbot_max_distance() {
    AIMBOT_MAX_DISTANCE=$(get_ini_value "AIMBOT_MAX_DISTANCE" "500")
    AIMBOT_MAX_DISTANCE=$(get_valid_input "エイムボットの最大距離" "$AIMBOT_MAX_DISTANCE")
    update_ini "AIMBOT_MAX_DISTANCE" "$AIMBOT_MAX_DISTANCE"
}

change_aimbot_min_distance() {
    AIMBOT_MIN_DISTANCE=$(get_ini_value "AIMBOT_MIN_DISTANCE" "0")
    AIMBOT_MIN_DISTANCE=$(get_valid_input "エイムボットの最小距離" "$AIMBOT_MIN_DISTANCE")
    update_ini "AIMBOT_MIN_DISTANCE" "$AIMBOT_MIN_DISTANCE"
}

change_aimbot_activated_by_attack() {
    AIMBOT_ACTIVATED_BY_ATTACK=$(get_ini_value "AIMBOT_ACTIVATED_BY_ATTACK" "ON")
    AIMBOT_ACTIVATED_BY_ATTACK=$(get_valid_radiolist "発射時にエイムボットを発動させますか？" \
        "YES 発射時にエイムボットを有効にする ON NO 発射時には無効にする OFF")
    update_ini "AIMBOT_ACTIVATED_BY_ATTACK" "$AIMBOT_ACTIVATED_BY_ATTACK"
}

change_aimbot_activated_by_ads() {
    AIMBOT_ACTIVATED_BY_ADS=$(get_ini_value "AIMBOT_ACTIVATED_BY_ADS" "ON")
    AIMBOT_ACTIVATED_BY_ADS=$(get_valid_radiolist "ADS（Aim Down Sights）時にエイムボットを発動させますか？" \
        "YES ADS時にエイムボットを有効にする ON NO ADS時には無効にする OFF")
    update_ini "AIMBOT_ACTIVATED_BY_ADS" "$AIMBOT_ACTIVATED_BY_ADS"
}





# Glowのサブメニュー
# カラーピッカーを使用してRGB値を選択
pick_color() {
    local color=$(zenity --color-selection --title="色を選択してください")

    # カラーピッカーが返す値をデバッグとして表示
    echo "選択された色: $color" >&2

    # カラーピッカーがキャンセルされた場合、空文字列になることを確認
    if [[ -z "$color" ]]; then
        echo "キャンセルされました" >&2
        echo ""  # 空文字列を返す
        return
    fi

    # Zenityがrgb形式で返す場合を処理
    if [[ "$color" =~ ^rgb\([0-9]{1,3},[0-9]{1,3},[0-9]{1,3}\)$ ]]; then
        # rgb(R, G, B)形式から値を抽出
        local r=$(echo "$color" | sed -E 's/rgb\(([0-9]{1,3}),[0-9]{1,3},[0-9]{1,3}\)/\1/')
        local g=$(echo "$color" | sed -E 's/rgb\([0-9]{1,3},([0-9]{1,3}),[0-9]{1,3}\)/\1/')
        local b=$(echo "$color" | sed -E 's/rgb\([0-9]{1,3},[0-9]{1,3},([0-9]{1,3})\)/\1/')
        echo "$r $g $b"  # RGBの値を返す
    else
        echo "不正な形式またはキャンセルされました。" >&2
        echo ""  # 空文字列を返す
    fi
}

# Glowのサブメニュー
show_sense_menu() {
    while true; do
        CHOICE=$(zenity --list --title="Glow設定メニュー" --text="設定項目を選択してください" \
            --column="番号" --column="設定項目" \
            --width=600 --height=400 \
            --hide-header \
            "1" "Glowの最大距離" \
            "2" "Glowの色を選択" \
            "3" "メインメニューに戻る")

        # CHOICEが空の場合はメインメニューに戻る
        if [[ -z "$CHOICE" ]]; then
            break
        fi

        case $CHOICE in
            1) change_glow_maxrange ;;
            2) change_glow_color ;;
            3) break ;;
        esac
    done
}

# Glow設定の最大距離を変更する関数
change_glow_maxrange() {
    SENSE_MAXRANGE=$(get_ini_value "SENSE_MAXRANGE" "500")
    SENSE_MAXRANGE=$(get_valid_input "Glowの最大距離" "$SENSE_MAXRANGE")
    update_ini "SENSE_MAXRANGE" "$SENSE_MAXRANGE"
}

# Glowの色を変更する関数（カラーピッカー使用）
change_glow_color() {
    rgb=$(pick_color)

    # デバッグ: RGB値が何になっているか確認
    echo "取得したRGB値: $rgb" >&2

    if [[ -n "$rgb" ]]; then
        read Red Green Blue <<< "$rgb"
        update_ini "Red" "$Red"
        update_ini "Green" "$Green"
        update_ini "Blue" "$Blue"
        zenity --info --text="色が設定されました。Red: $Red, Green: $Green, Blue: $Blue"
        echo "Red: $Red, Green: $Green, Blue: $Blue" >&2
    else
        zenity --info --text="色の選択がキャンセルされました。"
    fi
}

# 入力値が空でないか、かつ不正な文字がないか確認する関数
get_valid_input() {
    local prompt_message=$1
    local current_value=$2
    local result=""
    
    while true; do
        result=$(zenity --entry --title="入力" --text="$prompt_message" --entry-text="$current_value")
        
        if [[ -z "$result" ]]; then
            zenity --error --text="値を入力してください！空の値は許可されていません。"
        elif [[ "$result" =~ [^a-zA-Z0-9_.-] ]]; then
            zenity --error --text="不正な文字が含まれています。もう一度入力してください。"
        else
            echo "$result"
            break
        fi
    done
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

    # Convert current values to dialog-friendly format (TRUE for YES, FALSE for NO)
    AIMBOT_STATUS=$( [[ "$FEATURE_AIMBOT_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )
    SENSE_STATUS=$( [[ "$FEATURE_SENSE_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )
    ITEM_GLOW_STATUS=$( [[ "$FEATURE_ITEM_GLOW_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )
    NORECOIL_STATUS=$( [[ "$FEATURE_NORECOIL_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )
    TRIGGERBOT_STATUS=$( [[ "$FEATURE_TRIGGERBOT_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )
    SPECTATOR_STATUS=$( [[ "$FEATURE_SPECTATOR_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )
    SKINCHANGER_STATUS=$( [[ "$FEATURE_SKINCHANGER_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )
    SUPER_GLIDE_STATUS=$( [[ "$FEATURE_SUPER_GLIDE_ON" == "YES" ]] && echo "TRUE" || echo "FALSE" )

    # Check box menu to toggle features
    choices=$(zenity --list --checklist --title="機能のオンオフ" --column="選択" --column="機能" \
        --width=600 --height=600 \
        $AIMBOT_STATUS "Aimbot" \
        $SENSE_STATUS "Glow" \
        $ITEM_GLOW_STATUS "アイテムGlow" \
        $NORECOIL_STATUS "アンチリコイル" \
        $TRIGGERBOT_STATUS "トリガーボット" \
        $SPECTATOR_STATUS "観戦者" \
        $SKINCHANGER_STATUS "スキンチェンジャー" \
        $SUPER_GLIDE_STATUS "スパグラ" \
        --separator=":")

    # リストが空か確認（キャンセルされた場合など）
    if [[ -z "$choices" ]]; then
        zenity --error --text="何も選択されていません。"
        return
    fi

    # Reset all features to "NO"
    update_ini "FEATURE_AIMBOT_ON" "NO"
    update_ini "FEATURE_SENSE_ON" "NO"
    update_ini "FEATURE_ITEM_GLOW_ON" "NO"
    update_ini "FEATURE_NORECOIL_ON" "NO"
    update_ini "FEATURE_TRIGGERBOT_ON" "NO"
    update_ini "FEATURE_SPECTATOR_ON" "NO"
    update_ini "FEATURE_SKINCHANGER_ON" "NO"
    update_ini "FEATURE_SUPER_GLIDE_ON" "NO"

    # Process user selections by splitting the "choices" based on ":"
    IFS=":" read -ra SELECTED_ITEMS <<< "$choices"

    for choice in "${SELECTED_ITEMS[@]}"; do
        case $choice in
            "Aimbot") update_ini "FEATURE_AIMBOT_ON" "YES" ;;
            "Glow") update_ini "FEATURE_SENSE_ON" "YES" ;;
            "アイテムGlow") update_ini "FEATURE_ITEM_GLOW_ON" "YES" ;;
            "アンチリコイル") update_ini "FEATURE_NORECOIL_ON" "YES" ;;
            "トリガーボット") update_ini "FEATURE_TRIGGERBOT_ON" "YES" ;;
            "観戦者") update_ini "FEATURE_SPECTATOR_ON" "YES" ;;
            "スキンチェンジャー") update_ini "FEATURE_SKINCHANGER_ON" "YES" ;;
            "スパグラ") update_ini "FEATURE_SUPER_GLIDE_ON" "YES" ;;
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
