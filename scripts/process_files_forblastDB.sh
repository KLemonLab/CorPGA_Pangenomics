#!/bin/bash

# Check if the number of command-line arguments is correct
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <source_folder> <extension> <output_folder> <output_file>"
  exit 1
fi

source_folder="$1"
extension="$2"
output_folder="$3"
output_file="$4"

# Verify that the specified source folder exists
if [ ! -d "$source_folder" ]; then
  echo "Source folder '$source_folder' does not exist."
  exit 1
fi

# Verify that the specified output folder exists or create it if it doesn't
if [ ! -d "$output_folder" ]; then
  mkdir -p "$output_folder"
fi

# Initialize an empty output file
> "$output_file"

# Iterate through all files with the given extension in the source folder
for file in "$source_folder"/*"$extension"; do
  if [ -f "$file" ]; then
    # Get the filename without the path
    filename=$(basename "$file")
    
    # Replace the FASTA headers using seqkit
    seqkit replace -p "\s.+" "$file" > "$output_folder/clean_$filename"
    seqkit replace -p $ -r "_$filename" "$output_folder/clean_$filename" > "$output_folder/renamed_clean_$filename"

    # Concatenate the modified file to the output file
    cat "$output_folder/renamed_clean_$filename" >> "$output_folder/$output_file"
  fi
done

find "$output_folder" -type f -name "*clean*" -exec rm -f {} \;

echo "Concatenation complete. Result saved to $output_file in $output_folder"
