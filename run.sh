
sudo clear

 

handle_error() {
    echo "Error: $1"
    exit 1
}
 

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 

log_file="$script_dir/script_log.txt"
 

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$log_file" || handle_error "Failed to write to log file: $log_file"
}
 

mkdir -p "$script_dir" || handle_error "Failed to create log directory: $script_dir"
 

log "Script started"
 

original_binary_name="ApexLinux"
 

temp_binary_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
 

temp_binary_path="/$script_dir/$temp_binary_name"
 

if ! cp "$script_dir/$original_binary_name" "$temp_binary_path"; then
    log "Failed to copy binary: $script_dir/$original_binary_name to $temp_binary_path"
    exit 1
fi
log "Binary copied: $script_dir/$original_binary_name to $temp_binary_path"
 

log "Executing binary: $temp_binary_name"


sleep 0.3
echo "Executing $original_binary_name as $temp_binary_name"
sleep 0.3

(sudo env XDG_RUNTIME_DIR="/run/user/0" "./$temp_binary_name") & pid=$! 
log "Binary executed with PID: $pid"
 

if echo "$pid" | sudo tee /proc/sys/kernel/ns_last_pid > /dev/null; then
    log "Process ID $pid hidden successfully"
    

    child_pids=$(pgrep -P $pid)
    for child_pid in $child_pids; do
        if echo "$child_pid" | sudo tee /proc/sys/kernel/ns_last_pid > /dev/null; then
            log "Child process ID $child_pid hidden successfully"
        else
            log "Failed to hide child process ID $child_pid"
        fi
    done
else
    log "Failed to hide process ID $pid"
fi
 

if ! wait $pid; then

    log "Deleting binary with PID: $pid"
    rm "$temp_binary_name"
    exit 1
fi
 
log "Binary execution completed"
 

log "Script completed"
