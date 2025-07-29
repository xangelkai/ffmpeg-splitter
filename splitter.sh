#!/bin/bash

input_file=$(zenity --file-selection --title="Select input video file" 2>/dev/null)
[ -z "$input_file" ] && exit 1

target_size_mb=$(zenity --entry --title="Segment size" --text="Enter segment size in MB:" 2>/dev/null)
[[ ! "$target_size_mb" =~ ^[0-9]+$ ]] && exit 1

bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")
[[ ! "$bitrate" =~ ^[0-9]+$ ]] && zenity --error --text="Invalid bitrate: '$bitrate'" 2>/dev/null && exit 1

target_size_bits=$((target_size_mb * 1024 * 1024 * 8))
segment_time=$((target_size_bits / bitrate))

[[ "$segment_time" -le 0 ]] && zenity --error --text="Segment time calculation failed." 2>/dev/null && exit 1

base_name=$(basename "$input_file")
extension="${base_name##*.}"
name="${base_name%.*}"
output_prefix="${name}_part_"

ffmpeg -i "$input_file" -c copy -map 0 -f segment -segment_time "$segment_time" -reset_timestamps 1 "${output_prefix}%03d.${extension}"
