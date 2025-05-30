#!/bin/bash

# Check for required argument
if [ -z "$1" ]; then
  echo "Usage: $0 <search_directory>"
  exit 1
fi

# Set the directory to search from first argument
SEARCH_DIR="$1"

## New base path to use
if [[ $(basename "$SEARCH_DIR") == Library-* ]]; then
  NEW_BASE_PATH="..\\build\\extensions"
else
  NEW_BASE_PATH="..\\..\\build\\extensions"
fi

# Find all .csproj files in the directory (recursively)
find "$SEARCH_DIR" -type f -name "*.csproj" | while read -r csproj_file; do
  echo "Updating OutputPaths in $csproj_file ..."

 # Check if OutputPath exists
  if ! xmlstarlet sel -t -v "//OutputPath" "$csproj_file" 2>/dev/null | grep -q .; then
    echo " - OutputPath missing; inserting $NEW_BASE_PATH"
    xmlstarlet ed -L \
      -s "//PropertyGroup[1]" \
      -t elem -n "OutputPath" -v "$NEW_BASE_PATH" \
      "$csproj_file"
    continue
  fi

  # Extract all current OutputPath values
  mapfile -t output_paths < <(xmlstarlet sel -t -v "//OutputPath" -n "$csproj_file")

  for old_path in "${output_paths[@]}"; do
    # Construct new OutputPath value
    new_path="$NEW_BASE_PATH"

    echo " - Replacing: $old_path -> $new_path"

    # Update the OutputPath in the XML
    xmlstarlet ed -L \
      -u "//OutputPath[text()='$old_path']" \
      -v "$new_path" \
      "$csproj_file"
  done
done
