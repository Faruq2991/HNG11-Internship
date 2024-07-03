#!/bin/bash

# Declare the arrays to hold user and groups data
declare -a users
declare -a groups

# Check if the script is run with exactly one argument
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

# The input file
input_file="$1"

# Confirming the input file
echo "Reading input file: $input_file"

function read_input() {
  local file="$1"

  # Check if file exists
  if [[ ! -f "$file" ]]; then
    echo "File not found!"
    return 1
  fi

  while IFS= read -r line; do
    user=$(echo "$line" | cut -d';' -f1)
    groups_list=$(echo "$line" | cut -d';' -f2 | tr -d '[:space:]')
    users+=("$user")
    groups+=("$groups_list")
  done < "$file"
}

# Call the function with the input file
read_input "$input_file"

# Print the arrays for verification
echo "Users: ${users[@]}"
echo "Groups: ${groups[@]}"

log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.csv"

touch $log_file
mkdir -p $(dirname $password_file)
touch $password_file

# Write CSV header
echo "Username,Password" > $password_file

for (( i = 0; i < ${#users[@]}; i++ )); 
do
  user="${users[$i]}"
  user_groups="${groups[$i]}"
  if id "$user" &>/dev/null; then
    echo "User $user exists. Not duplicated" | tee -a "$log_file"
  else
    # Create user
    useradd -m -s /bin/bash "$user"
    if [[ $? -ne 0 ]]; then
      echo "Failed to create user $user" | tee -a "$log_file"
      exit 1
    fi
    echo "User $user created" | tee -a "$log_file"

    password=$(openssl rand -base64 50 | tr -dc 'A-Za-z0-9!?%=' | head -c 10)
    echo "$user:$password" | chpasswd
    if [[ $? -ne 0 ]]; then
      echo "Failed to set password for $user" | tee -a "$log_file"
      exit 1
    fi
    echo "Password for $user set" | tee -a "$log_file"
    echo "$user,$password" >> "$password_file"

    # Add user to personal group
    usermod -aG "$user" "$user"
    if [[ $? -ne 0 ]]; then
      echo "Failed to add $user to $user group" | tee -a "$log_file"
      exit 1
    fi
    echo "Added $user to $user group" | tee -a "$log_file"

    # Process additional groups
    IFS=',' read -ra GROUP_LIST <<< "$user_groups"
    for group in "${GROUP_LIST[@]}"; do
      if grep -q "^$group:" /etc/group; then
        echo "Group $group exists" | tee -a "$log_file"
      else
        echo "Group $group does not exist, creating $group" | tee -a "$log_file"
        groupadd "$group"
        if [[ $? -ne 0 ]]; then
          echo "Failed to create group $group" | tee -a "$log_file"
          exit 1
        fi
      fi

      usermod -aG "$group" "$user"
      if [[ $? -ne 0 ]]; then
        echo "Failed to add $user to $group group" | tee -a "$log_file"
        exit 1
      fi
      echo "Added $user to $group group" | tee -a "$log_file"
    done
  fi
done

echo "Process successfully  completed." | tee -a "$log_file"
