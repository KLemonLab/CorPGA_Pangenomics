#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <FolderPath> <RenamingFile.txt>"
  exit 1
fi

folder_path="$1"
input_file="$2"

# Check if the input file exists
if [ ! -f "$folder_path/$input_file" ]; then
  echo "File not found: $folder_path/$input_file"
  exit 1
fi

# Generate a timestamp in the format: YYYYMMDD_HHMMSS
timestamp=$(date +'%Y%m%d_%H%M%S')

# Rename the input file with the timestamp
new_filename="${timestamp}_RenamingLog.txt"
mv "$folder_path/$input_file" "$folder_path/$new_filename"

echo "Renamed $folder_path/$input_file to $folder_path/$new_filename"

# Use tail to skip the first line (header) and loop through each subsequent line
tail -n +2 "$folder_path/$new_filename" | while IFS=' ' read -r original renamed; do
  # Check if the original file exists
  if [ -f "$folder_path/$original" ]; then
    # Rename the file
    mv "$folder_path/$original" "$folder_path/$renamed"
    echo "Renamed: $folder_path/$original -> $folder_path/$renamed"
  else
    echo "File not found: $folder_path/$original"
  fi
done
