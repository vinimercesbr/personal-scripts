
#!/usr/bin/env bash
# Working directories
TARGET_DIR="/mnt/btrfs"

# Directory for the subvolume
DATA_SUBVOLUME="$TARGET_DIR/data_files"
SNAPSHOT_DIR="$TARGET_DIR/snapshots"

# Log file to record actions
LOG_FILE="$HOME/btrfs_operations.log"

# Function to create subvolumes if they don't exist
create_subvolume_if_not_exists() {
    local subvolume_path="$1"
    if [ ! -d "$subvolume_path" ]; then
        echo "Subvolume not found: $subvolume_path. Creating..."
        btrfs subvolume create "$subvolume_path"
        if [ $? -ne 0 ]; then
          echo "Error creating subvolume: $subvolume_path"
          exit 1
        fi
    else
        echo "Subvolume already exists: $subvolume_path."
    fi
}

# Function to move files to the subvolume
move_files_to_subvolume() {
    local directory="$1"
    local subvolume_path="$2"
    local file_type="$3"
    
    # Find files and move to the subvolume
    echo "Moving $file_type files from $directory to $subvolume_path..."
    find "$directory" -type f -print0 | xargs -0 -I {} mv -i {} "$subvolume_path/"
    
    # Operation log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Moved: $file_type from $directory to $subvolume_path" >> "$LOG_FILE"
}

# Function to create snapshots of subvolumes
create_snapshot() {
    local subvolume_path="$1"
    local snapshot_name="$2"
    
    echo "Creating snapshot of $subvolume_path at $snapshot_name..."
    btrfs subvolume snapshot "$subvolume_path" "$snapshot_name"
    if [ $? -ne 0 ]; then
      echo "Error creating snapshot: $snapshot_name"
      exit 1
    fi
    
    # Operation log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Snapshot created: $snapshot_name" >> "$LOG_FILE"
}

# Ask the user for the source directory
read -p "Enter the source directory path (or press Enter for $HOME/Documents): " source_dir
if [ -z "$source_dir" ]; then
  source_dir="$HOME/Documents"
fi

# Check if the directory exists
if [ ! -d "$source_dir" ]; then
  read -p "The directory $source_dir does not exist. Do you want to create it? (y/n): " create_dir
  if [ "$create_dir" == "y" ]; then
    mkdir -p "$source_dir"
    echo "Directory $source_dir created."
  else
    echo "Directory not created. Exiting."
    exit 1
  fi
fi

# Create subvolume for files, if not exists
create_subvolume_if_not_exists "$DATA_SUBVOLUME"

# Create subvolume for snapshots, if not exists
create_subvolume_if_not_exists "$SNAPSHOT_DIR"

# Move all files to the subvolume
move_files_to_subvolume "$source_dir" "$DATA_SUBVOLUME" "*"

# Create snapshots of subvolumes
create_snapshot "$DATA_SUBVOLUME" "$SNAPSHOT_DIR/data_files_snapshot_$(date +%Y%m%d_%H%M%S)"

echo "Script completed successfully!"