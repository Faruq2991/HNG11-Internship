# HNG11-Internship

# User and Group Management Script

This script automates the creation of users and groups on a Linux system. It reads a list of users and their respective groups from an input file, creates the users and groups if they do not already exist, sets up home directories, assigns random passwords, and logs all actions. Additionally, the generated passwords are securely stored in a CSV file.

## Features

- **User Creation**: Adds new users to the system with a home directory and a bash shell.
- **Group Management**: Creates and assigns groups to users, including personal groups.
- **Password Generation**: Generates a random password for each user.
- **Logging**: Logs all actions to `/var/log/user_management.log`.
- **Secure Storage**: Stores generated passwords in a CSV file located at `/var/secure/user_passwords.csv`.

## Prerequisites

- Ensure you have `openssl` installed for password generation.
- The script should be run with root privileges to modify user and group settings.

## Input File Format

The script requires an input file (`ninput.txt`) with the following format:

```
username;group1,group2
```

Each line should contain a username followed by a semicolon and a comma-separated list of groups.

## Usage

1. Create an input file (`input.txt`) with the desired usernames and groups.
2. Run the script with the input file as an argument:

   ```bash
sudo ./create_users.sh input.txt
   ```

## Script Workflow

1. **Input Validation**: The script checks if the correct number of arguments is provided and if the input file exists.
2. **Reading Input**: It reads the usernames and groups from the input file and stores them in arrays.
3. **User and Group Creation**:
   - Checks if each user already exists. If so, it skips the creation process for that user.
   - Creates the user and assigns a random password.
   - Adds the user to their personal group and any additional groups specified.
   - Logs each action and any errors encountered.
4. **Password Storage**: Stores the generated passwords in a CSV file for secure reference.

## Example

Input file (`input.txt`):

```
alice;dev,ops
bob;admin,dev,www-data
```

Running the script:

```bash
sudo ./create_users.sh input.txt
```

This will create users `alice` and `bob`, assign them to the specified groups, generate passwords, and log all actions.

## Log and Password Files

- **Log File**: `/var/log/user_management.log` - Contains logs of all actions performed by the script.
- **Password File**: `/var/secure/user_passwords.csv` - Contains the generated passwords in CSV format (`Username,Password`).

## Notes

- The script should be run with root privileges.
- Ensure the input file follows the specified format to avoid errors.
- Generated passwords are stored securely, but it's recommended to change them after the initial setup for enhanced security.