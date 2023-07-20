#!/bin/bash
#
if [ -z $1 ]; then echo "please provide path to to the training data created with create_train_data_lines" && exit 1; fi;
if [ -z $2 ]; then echo "please provide output path" && exit 1; fi;

# Define the input file, target directory, and output directory
input_file="$1/training_all_train.txt"
target_directory=$1
output_directory=$2

# Create the output directory if it doesn't exist
mkdir -p "$output_directory"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Input file not found: $input_file"
  exit 1
fi

# Check if the target directory exists
if [ ! -d "$target_directory" ]; then
  echo "Target directory not found: $target_directory"
  exit 1
fi

# Read each line in the input file
while IFS= read -r line; do
  # Extract the filename from the first entry of the line using awk
  filename=$(echo "$line" | awk '{print $1}')

  # Remove the file path from the filename using basename
  filename=$(basename "$filename")

  # Remove the ".png" suffix from the filename
  filename=${filename%.png}

  echo "Extracted filename: $filename"

  # Check if the .txt file exists for the filename in the target directory and its subdirectories
  txt_files=$(find "$target_directory" -type f -name "$filename.txt")

  # Check if the .png file exists for the filename in the target directory and its subdirectories
  png_files=$(find "$target_directory" -type f -name "$filename.png")

  # Copy the files to the output directory if found
  if [ -n "$txt_files" ] && [ -n "$png_files" ]; then
    cp "$txt_files" "$output_directory"
    cp "$png_files" "$output_directory"
    echo "Copied files: $filename.txt and $filename.png"
  else
    echo "Files not found for filename: $filename"
  fi
done < "$input_file"