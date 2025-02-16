#!/usr/bin/env bash
# Directories
DIR_MOUNT="/mnt"

# Function to list users
list_users() {
    echo "Users available on the system:"
    cut -d: -f1 /etc/passwd
    echo
}

# Function to get the user's home directory
get_user_home() {
    while true; do
        echo -n "Enter the username to determine the home directory (or 'exit' to cancel): "
        read USERNAME

        if [[ "$USERNAME" == "exit" ]]; then
            return 1
        fi

        DIR_HOME=$(eval echo ~$USERNAME)

        # Check if the home directory exists
        if [ ! -d "$DIR_HOME" ]; then
            echo "Error: User '$USERNAME' does not exist or home directory not found!"
        else
            echo "Home directory for user $USERNAME is $DIR_HOME"
            return 0
        fi
    done
}

# Function to create a Btrfs filesystem
create_filesystem() {
    lsblk -f | grep sd
    echo -n "Enter the device to create the filesystem (e.g., /dev/sda1): "
    read DEVICE

    # Check if the device exists
    if [ ! -b "$DEVICE" ]; then
        echo "Error: Device '$DEVICE' not found or not a block device!"
        return 1
    fi

    echo "Creating Btrfs filesystem on $DEVICE..."
    if ! sudo mkfs.btrfs -f $DEVICE; then
        echo "Error creating filesystem on $DEVICE!"
        return 1
    fi
    echo "Filesystem created successfully on $DEVICE."
}

# Function to mount a Btrfs filesystem
mount_filesystem() {
    echo -n "Enter the device to mount the filesystem (e.g., /dev/sda1): "
    read DEVICE

    # Check if the device exists
    if [ ! -b "$DEVICE" ]; then
        echo "Error: Device '$DEVICE' not found or not a block device!"
        return 1
    fi

    echo "Mounting Btrfs filesystem on $DIR_MOUNT..."
    if ! sudo mount $DEVICE $DIR_MOUNT; then
        echo "Error mounting filesystem on $DEVICE!"
        return 1
    fi
    echo "Filesystem mounted on $DIR_MOUNT."
}

# Function to create a subvolume
create_subvolume() {
    echo -n "Enter the name of the subvolume to be created: "
    read SUBVOLUME_NAME

    # Check if the subvolume already exists
    if [ -d "$DIR_MOUNT/$SUBVOLUME_NAME" ]; then
        echo "Error: Subvolume '$SUBVOLUME_NAME' already exists!"
        return 1
    fi

    echo "Creating subvolume $SUBVOLUME_NAME..."
    if ! sudo btrfs subvolume create $DIR_MOUNT/$SUBVOLUME_NAME; then
        echo "Error creating subvolume!"
        return 1
    fi
    echo "Subvolume $SUBVOLUME_NAME created successfully."
}

# Function to list subvolumes
list_subvolumes() {
    echo "Listing subvolumes..."
    sudo btrfs subvolume list $DIR_MOUNT
}

# Function to create a snapshot
create_snapshot() {
    if [ ! -d "$DIR_HOME/.snapshots" ]; then
        mkdir -p $DIR_HOME/.snapshots
    fi
    SNAPSHOT_NAME=$(date +%Y-%m-%d_%H-%M-%S)
    echo "Creating snapshot $SNAPSHOT_NAME..."
    if ! sudo btrfs subvolume snapshot $DIR_HOME $DIR_HOME/.snapshots/$SNAPSHOT_NAME; then
        echo "Error creating snapshot!"
        return 1
    fi
    echo "Snapshot $SNAPSHOT_NAME created successfully."
}

# Function to list snapshots
list_snapshots() {
    echo "Listing snapshots..."
    sudo btrfs subvolume list $DIR_HOME/.snapshots
}

# Function to restore a snapshot
restore_snapshot() {
    echo "Available snapshots:"
    list_snapshots

    while true; do
        echo -n "Enter the name of the snapshot to be restored (or 'exit' to cancel): "
        read SNAP_NAME

        if [[ "$SNAP_NAME" == "exit" ]]; then
            return 1
        fi

        if [ ! -d "$DIR_HOME/.snapshots/$SNAP_NAME" ]; then
            echo "Error: Snapshot '$SNAP_NAME' not found!"
        else
            if ! sudo btrfs subvolume set-default $DIR_HOME/.snapshots/$SNAP_NAME; then
                echo "Error restoring snapshot!"
                return 1
            fi
            echo "Snapshot restored: $SNAP_NAME"
            return 0
        fi
    done
}

# Function to perform a filesystem scrub
scrub_filesystem() {
    echo "Starting filesystem scrub..."
    if ! sudo btrfs scrub start $DIR_MOUNT; then
        echo "Error starting filesystem scrub!"
        return 1
    fi
    echo "Filesystem scrub started successfully."
}

# Function to balance filesystem data
balance_filesystem() {
    echo "Starting filesystem balance..."
    if ! sudo btrfs balance start $DIR_MOUNT; then
        echo "Error starting filesystem balance!"
        return 1
    fi
    echo "Filesystem balance started successfully."
}

# Function to check the filesystem
check_filesystem() {
    echo -n "Enter the device to check the filesystem (e.g., /dev/sda1): "
    read DEVICE

    # Check if the device exists
    if [ ! -b "$DEVICE" ]; then
        echo "Error: Device '$DEVICE' not found or not a block device!"
        return 1
    fi

    echo "Checking filesystem on $DEVICE..."
    if ! sudo btrfs check $DEVICE; then
        echo "Error checking filesystem on $DEVICE!"
        return 1
    fi
    echo "Filesystem checked successfully."
}

# Menu
list_users  # List users before any other option

while true; do
    echo "Choose an option:"
    echo "1. Create Btrfs filesystem"
    echo "2. Mount Btrfs filesystem"
    echo "3. Create subvolume"
    echo "4. List subvolumes"
    echo "5. Create snapshot"
    echo "6. List snapshots"
    echo "7. Restore snapshot"
    echo "8. Perform filesystem scrub"
    echo "9. Balance filesystem data"
    echo "10. Check filesystem"
    echo "0. Exit"
    echo -n "Option: "
    read OPTION

    case $OPTION in
        1)
            create_filesystem
            ;;
        2)
            mount_filesystem
            ;;
        3)
            create_subvolume
            ;;
        4)
            list_subvolumes
            ;;
        5)
            if get_user_home; then
                create_snapshot
            fi
            ;;
        6)
            if get_user_home; then
                list_snapshots
            fi
            ;;
        7)
            if get_user_home; then
                restore_snapshot
            fi
            ;;
        8)
            scrub_filesystem
            ;;
        9)
            balance_filesystem
            ;;
        10)
            check_filesystem
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac
done