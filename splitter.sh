#!/bin/bash

export G_MESSAGES_DEBUG=none

for cmd in ffprobe ffmpeg zenity; do
    command -v "$cmd" >/dev/null 2>&1 || {
        zenity --error --text="$cmd not found. Please install it before running this script." 2>/dev/null
        exit 1
    }
done

input_file=$(zenity --file-selection --title="Select a video file to split" 2>/dev/null)
if [[ -z "$input_file" ]]; then
    zenity --error --text="No file selected. Exiting." 2>/dev/null
    exit 1
fi

bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")
if ! [[ "$bitrate" =~ ^[0-9]+$ ]]; then
    zenity --error --text="Invalid bitrate: '$bitrate'. Cannot continue." 2>/dev/null
    exit 1
fi

size_mb=$(zenity --entry --title="Chunk Size" --text="Enter desired chunk size in MB (e.g. 1024):" 2>/dev/null)
if [[ -z "$size_mb" || "$size_mb" -eq 0 || ! "$size_mb" =~ ^[0-9]+$ ]]; then
    zenity --error --text="Invalid size. Exiting." 2>/dev/null
    exit 1
fi

size_bits=$((size_mb * 1024 * 1024 * 8))
segment_time=$((size_bits / bitrate))

if [[ "$segment_time" -le 0 ]]; then
    zenity --error --text="Calculated segment time is zero. Size might be too small." 2>/dev/null
    exit 1
fi

zenity --question --width=400 --title="Confirm Split" \
    --text="📁 File: $input_file\n🎯 Chunk size: ${size_mb} MB\n📈 Bitrate: $bitrate bits/sec\n⏱️ Chunk duration: ~${segment_time} sec\n\nStart splitting?" 2>/dev/null

if [[ $? -ne 0 ]]; then
    zenity --info --text="Operation cancelled." 2>/dev/null
    exit 0
fi

output_prefix="chunk_"
ffmpeg -i "$input_file" -c copy -map 0 -f segment -segment_time "$segment_time" \
       -reset_timestamps 1 "${output_prefix}%03d.mp4"

zenity --info --text="✅ Splitting complete!\nFiles saved as: ${output_prefix}###.mp4" 2>/dev/null
