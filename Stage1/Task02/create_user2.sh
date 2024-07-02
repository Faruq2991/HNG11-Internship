#!/bin/bash

# Number of users to generate
NUM_USERS=${NUM_USERS:-10}
# Output file for generated usernames and groups
OUTPUT_FILE=${OUTPUT_FILE:-generated_users.txt}

generate_random_string() {
  local LENGTH=$1
  tr -dc A-Za-z0-9 </dev/urandom | head -c "$LENGTH"
}

# Predefined group names
GROUPS=("dev" "ops" "www" "admin" "support")

# Function to generate random groups for a user
generate_random_groups() {
  local NUM_GROUPS=$(shuf -i 1-4 -n 1)  # Random number of groups between 1 and 4
  local SELECTED_GROUPS=()
  while [ ${#SELECTED_GROUPS[@]} -lt $NUM_GROUPS ]; do
    local GROUP=${GROUPS[$RANDOM % ${#GROUPS[@]}]}
    if [[ ! " ${SELECTED_GROUPS[@]} " =~ " $GROUP " ]]; then
      SELECTED_GROUPS+=("$GROUP")
    fi
  done
  echo "${SELECTED_GROUPS[*]}"
}

# Generate random usernames and assign random groups
> "$OUTPUT_FILE"
for ((i = 1; i <= NUM_USERS; i++)); do
  username="user_$(generate_random_string 6)"
  group="${GROUPS[$RANDOM % ${#GROUPS[@]}]}"
  echo "$username;$group" >> "$OUTPUT_FILE"
done

echo "Random usernames and groups have been generated in $OUTPUT_FILE"

# Script to create users and groups from a file, set up home directories, generate passwords,
# and log all actions. 

# Input file containing usernames and groups
INPUT_FILE=$OUTPUT_FILE

# Log file
LOG_FILE="/var/log/user_management.log"

# Secure file to store passwords
SECURE_PASSWORD_FILE="/var/secure/user_passwords.txt"

# Check if the input file exists
if [[ ! -f $INPUT_FILE ]]; 
then
  echo "Input file $INPUT_FILE not found!" | tee -a $LOG_FILE
  exit 1
fi

# Function to generate a random password
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 16
}

# Ensure the log and password files exist
touch $LOG_FILE
mkdir -p $(dirname $SECURE_PASSWORD_FILE)
touch $SECURE_PASSWORD_FILE

# Process the input file
while IFS=';' read -r username group; 
do
  username=$(echo "$username" | xargs)  
  group=$(echo "$group" | xargs)     

  # Check if the user already exists
  if id -u "$username" >/dev/null 2>&1; 
  then
    echo "User $username already exists. Skipping creation." | tee -a $LOG_FILE
    continue
  fi

  # Create group if it does not exist
  if ! getent group "$group" >/dev/null 2>&1; 
  then
    groupadd "$group"
    echo "Group $group created." | tee -a $LOG_FILE
  fi

  # Create the user with the specified group
  useradd -m -G "$group" "$username"
  if [[ $? -ne 0 ]]; 
  then
    echo "Failed to create user $username." | tee -a $LOG_FILE
    continue
  fi
  echo "User $username created with group $group." | tee -a $LOG_FILE

  # Generate a random password for the user
  password=$(generate_password)
  echo "$username:$password" | chpasswd
  if [[ $? -ne 0 ]]; 
  then
    echo "Failed to set password for user $username." | tee -a $LOG_FILE
    continue
  fi

  # Securely store the generated password
  echo "$username:$password" >> $SECURE_PASSWORD_FILE
  chmod 600 $SECURE_PASSWORD_FILE

  # Set the appropriate permissions for the home directory
  chmod 700 "/home/$username"
  chown "$username:$username" "/home/$username"

  echo "Password for user $username generated and stored securely." | tee -a $LOG_FILE

done < "$INPUT_FILE"

echo "User creation process completed." | tee -a $LOG_FILE
