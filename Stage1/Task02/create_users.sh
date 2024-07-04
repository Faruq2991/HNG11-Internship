#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 <input_file>"
    exit 1
}

[[ $# -ne 1 ]] && usage

input_file="$1"
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.txt"

log() {
    echo "$1" | tee -a "$log_file"
}

setup_files() {
    mkdir -p "$(dirname "$log_file")" "$(dirname "$password_file")"
    touch "$log_file" "$password_file"
}

create_user() {
    local user="$1"
    local groups="$2"

    # Check for empty or invalid username
    if [[ -z "$user" || "$user" =~ [^a-zA-Z0-9_-] ]]; then
        log "Invalid or empty username: '$user'. Skipped."
        return
    fi

    if id "$user" &>/dev/null; then
        log "User $user already exists, skipped"
        return
    fi

    useradd -m -s /bin/bash "$user" && log "User $user created"

    local password
    password=$(openssl rand -base64 50 | tr -dc 'A-Za-z0-9!?%=' | head -c 10)
    echo "$user,$password" | chpasswd && log "Password for $user set"
    echo "$user,$password" >> "$password_file"

    manage_group "$user" "$user"

    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        [[ -n "$group" ]] && manage_group "$user" "$group"
    done
}

manage_group() {
    local user="$1"
    local group="$2"

    # Check for empty or invalid group name
    if [[ -z "$group" || "$group" =~ [^a-zA-Z0-9_-] ]]; then
        log "Invalid or empty group name: '$group' for user '$user'. Skipped."
        return
    fi

    if ! grep -q "^$group:" /etc/group; then
        groupadd "$group" && log "Group $group created"
    else
        log "Group $group already exists"
    fi

    usermod -aG "$group" "$user" && log "Added $user to $group group"
}

setup_files

while IFS=';' read -r user groups || [[ -n "$user" ]]; do
    create_user "$user" "$(echo "$groups" | tr -d '[:space:]')"
done < "$input_file"