#!/bin/bash

# Script to create users and groups from a file, set up home directories, generate passwords,
# and log all actions. 

# Input file containing usernames and groups
INPUT_FILE="employee_data.txt"

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
while IFS=';' read -r username groups; 
do
  username=$(echo "$username" | xargs)  
  groups=$(echo "$groups" | xargs)     
  # Check if the user already exists
  if id -u "$username" >/dev/null 2>&1; 
  then
    echo "User $username already exists. Skipping creation." | tee -a $LOG_FILE
    continue
  fi

  # Create groups if they do not exist
  IFS=',' read -ra GROUP_LIST <<< "$groups"
  for group in "${GROUP_LIST[@]}"; 
  do
    if ! getent group "$group" >/dev/null 2>&1; 
    
    then
      groupadd "$group"
      echo "Group $group created." | tee -a $LOG_FILE
    fi
  done

  # Create the user with the specified groups
  useradd -m -G "$groups" "$username"
  if [[ $? -ne 0 ]]; 
  then
    echo "Failed to create user $username." | tee -a $LOG_FILE
    continue
  fi
  echo "User $username created with groups $groups." | tee -a $LOG_FILE

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

