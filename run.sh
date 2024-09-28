#!/bin/bash

handle_error() {
    echo "Error: $1"
    exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
original_binary_name="dll1.out"
temp_binary_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
temp_binary_path="$script_dir/$temp_binary_name"

# 元のバイナリを一時ファイルにコピー
if ! cp "$script_dir/$original_binary_name" "$temp_binary_path"; then
    handle_error "Failed to copy the binary."
fi

# 一時ファイルをバックグラウンドで実行し、PIDを取得
(sudo env XDG_RUNTIME_DIR="/run/user/0" "./$temp_binary_name") & pid=$!

# ns_last_pidにPIDを書き込む処理
if echo "$pid" | sudo tee /proc/sys/kernel/ns_last_pid > /dev/null; then
    child_pids=$(pgrep -P $pid)
    for child_pid in $child_pids; do
        if echo "$child_pid" | sudo tee /proc/sys/kernel/ns_last_pid > /dev/null; then
            echo "Successfully"
        else
            echo "Failed to write child PID: $child_pid"
        fi
    done
else
    echo "Failed to write parent PID: $pid"
fi

# プロセスが終了するまで待機
if ! wait $pid; then
    handle_error "Process failed."
fi

# プロセスが終了したら一時ファイルを削除
rm "$temp_binary_path"
echo "Temporary file $temp_binary_name has been deleted."
