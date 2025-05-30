#!/bin/bash

# Check for required argument
if [ -z "$1" ]; then
  echo "Usage: $0 <search_directory>"
  exit 1
fi

## Set the directory to search from first argument
SEARCH_DIR="$1"

## New base path to use
if [[ $(basename "$SEARCH_DIR") == Library-* ]]; then
  NEW_BASE_PATH="..\\build\\extensions"
else
  NEW_BASE_PATH="..\\..\\build\\extensions"
fi

## Find all .csproj files in the directory (recursively)
find "$SEARCH_DIR" -type f -name "*.csproj" | while read -r csproj_file; do
  echo "Updating HintPaths in $csproj_file ..."

  ## Extract all current HintPath values
  mapfile -t hint_paths < <(xmlstarlet sel -t -v "//HintPath" -n "$csproj_file")

  for old_path in "${hint_paths[@]}"; do
    ## Convert to Unix-style path temporarily to extract DLL filename
    unix_path=$(echo "$old_path" | tr '\\' '/')
    filename=$(basename "$unix_path")

    ## Construct new HintPath value
    new_path="$NEW_BASE_PATH\\$filename"

    echo " - Replacing: $old_path -> $new_path"

    ## Update the HintPath in the XML
    xmlstarlet ed -L \
      -u "//HintPath[text()='$old_path']" \
      -v "$new_path" \
      "$csproj_file"
  done
done
