#!/bin/bash

# Display the menu
echo "Select an option:"
echo "1. Download Video"
echo "2. Download Audio"
echo "3. Download Playlist"
read -p "Option: " option

# Function to download video
download_video() {
    read -p "Enter the video URL: " url
    yt-dlp "$url"
}

# Function to download audio
download_audio() {
    read -p "Enter the audio URL: " url
    yt-dlp --extract-audio --audio-format mp3 "$url"
}

# Function to download playlist
download_playlist() {
    read -p "Enter the playlist URL: " url
    yt-dlp --yes-playlist "$url"
}

# Execute the corresponding function based on the selected option
case $option in
    1)
        download_video
        ;;
    2)
        download_audio
        ;;
    3)
        download_playlist
        ;;
    *)
        echo "Invalid option!"
        ;;
esac