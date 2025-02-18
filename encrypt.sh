#!/bin/bash

# Function to check if a required command is available
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install $1."
        exit 1
    fi
}

# Function to list files and folders
list_items() {
    local directory="$1"
    echo "Items in directory '$directory':"
    items=()
    index=1  # Start index from 1
    for item in "$directory"/*; do
        if [ -f "$item" ]; then
            echo "$index. [FILE] $(basename "$item")"
            items+=("$item")
            index=$((index + 1))
        elif [ -d "$item" ]; then
            echo "$index. [FOLDER] $(basename "$item")"
            items+=("$item")
            index=$((index + 1))
        fi
    done
}

# Function to encrypt files
encrypt_file() {
    local file="$1"
    local passphrase="$2"
    local encrypted_file="$file.gpg"

    echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 --symmetric -o "$encrypted_file" "$file"
    if [ $? -eq 0 ]; then
        echo "File '$file' successfully encrypted to '$encrypted_file'."
        # Backup original file before deleting
        mv "$file" "$file.bak"
        echo "Original file backed up to '$file.bak'."
        # Ask for confirmation before deleting original file
        read -p "Do you want to delete the original file '$file'? (y/n): " confirm_delete
        if [[ "$confirm_delete" == "y" ]]; then
            rm "$file.bak"
            echo "Original file '$file' deleted."
        fi
    else
        echo "Error encrypting '$file'."
    fi
}

# Function to encrypt folders
encrypt_folder() {
    local folder="$1"
    local passphrase="$2"
    local encrypted_folder="$folder.tar.gz.gpg"

    tar -czf "$folder.tar.gz" -C "$(dirname "$folder")" "$(basename "$folder")"
    echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 --symmetric -o "$encrypted_folder" "$folder.tar.gz"
    if [ $? -eq 0 ]; then
        echo "Folder '$folder' successfully encrypted to '$encrypted_folder'."
        # Backup original folder before deleting
        mv "$folder" "$folder.bak"
        echo "Original folder backed up to '$folder.bak'."
        # Ask for confirmation before deleting original folder
        read -p "Do you want to delete the original folder '$folder'? (y/n): " confirm_delete
        if [[ "$confirm_delete" == "y" ]]; then
            rm -rf "$folder.bak"
            echo "Original folder '$folder' deleted."
        fi
        rm "$folder.tar.gz"  # Remove the unencrypted tar.gz file
    else
        echo "Error encrypting folder '$folder'."
    fi
}

# Function to check passphrase strength
check_passphrase_strength() {
    local passphrase="$1"
    if [[ ${#passphrase} -lt 8 ]]; then
        echo "Error: The passphrase must be at least 8 characters long."
        return 1
    fi
    # Add more checks for complexity if needed (e.g., using regular expressions)
    return 0
}

# Check dependencies
check_dependency "gpg"
check_dependency "tar"

# Show the current directory
echo "Current directory: $(pwd)"

# Ask the user for the directory
read -p "Enter the path of the directory to be encrypted: " directory

# Check if the directory exists
if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' not found!"
    exit 1
fi

# List items in the directory
list_items "$directory"

# Ask the user which items to encrypt
echo "Enter the numbers of the items to be encrypted, separated by spaces (e.g., 1 2 3): "
read -a selection

# Ask for the encryption passphrase
read -s -p "Enter the encryption passphrase: " passphrase
echo

# Check passphrase strength
if ! check_passphrase_strength "$passphrase"; then
    exit 1
fi

# Encrypt the selected items
for index in "${selection[@]}"; do
    item="${items[$index - 1]}"  # Adjust index to match array starting from 0
    if [ -f "$item" ]; then
        encrypt_file "$item" "$passphrase"
    elif [ -d "$item" ]; then
        encrypt_folder "$item" "$passphrase"
    fi
done

echo "Encryption process completed!"
