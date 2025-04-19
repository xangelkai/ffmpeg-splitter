#!/bin/bash

# Silence GTK/Adwaita warnings
export G_MESSAGES_DEBUG=none

# Check dependencies
for cmd in ffprobe ffmpeg zenity; do
    command -v "$cmd" >/dev/null 2>&1 || {
        zenity --error --text="$cmd not found. Please install it before using this script." 2>/dev/null
        exit 1
    }
done

# File selection dialog
input_file=$(zenity --file-selection --title="Select a video file to split" 2>/dev/null)
if [[ -z "$input_file" ]]; then
    zenity --error --text="No file selected. Exiting." 2>/dev/null
    exit 1
fi

# Get video bitrate
bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate \
         -of default=noprint_wrappers=1:nokey=1 "$input_file")

if [[ -z "$bitrate" ]]; then
    zenity --error --text="Failed to retrieve bitrate. The file might be damaged or not a valid video." 2>/dev/null
    exit 1
fi

# Prompt for chunk size in MB
size_mb=$(zenity --entry --title="Chunk Size" --text="Enter desired size per chunk in MB (e.g. 1024):" 2>/dev/null)
if [[ -z "$size_mb" || "$size_mb" -eq 0 ]]; then
    zenity --error --text="Invalid or no size entered. Exiting." 2>/dev/null
    exit 1
fi

# Calculate duration
size_bits=$((size_mb * 1024 * 1024 * 8))
segment_time=$((size_bits / bitrate))

# Confirmation
zenity --question --width=400 --title="Confirm Split" \
    --text="✔ Bitrate: $bitrate bits/sec\n✔ Target size: ${size_mb}MB\n✔ Chunk duration: ~${segment_time} seconds\n\nStart splitting?" 2>/dev/null

if [[ $? -ne 0 ]]; then
    zenity --info --text="Operation cancelled." 2>/dev/null
    exit 0
fi

# Perform the split
output_prefix="chunk_"
ffmpeg -i "$input_file" -c copy -map 0 -f segment -segment_time "$segment_time" \
       -reset_timestamps 1 "${output_prefix}%03d.mp4"

zenity --info --text="✅ Splitting complete!\nFiles saved as: ${output_prefix}###.mp4" 2>/dev/null
