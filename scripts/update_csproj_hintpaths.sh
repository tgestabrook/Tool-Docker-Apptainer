#!/bin/bash

# Check for required argument
if [ -z "$1" ]; then
  echo "Usage: $0 <search_directory>"
  exit 1
fi

## Set the directory to search from first argument
SEARCH_DIR="$1"

## Parent of SEARCH_DIR (i.e., Core-Model-v8-LINUX), which holds build/extensions
SEARCH_DIR_PARENT=$(dirname "$SEARCH_DIR")

## Find all .csproj files in the directory (recursively)
find "$SEARCH_DIR" -type f -name "*.csproj" | while read -r csproj_file; do
  echo "Updating HintPaths in $csproj_file ..."

  ## Compute the path to build/extensions relative to this specific .csproj's
  ## directory, so repos get the right number of ".." components regardless of
  ## where their .csproj lives (repo root vs. src/ vs. deeper). Doing this per
  ## .csproj matters: e.g. Library-PnET-Cohort keeps its .csproj in src/ while
  ## Library-Universal-Cohort keeps its at the repo root.
  csproj_dir=$(dirname "$csproj_file")
  rel_up=$(realpath --relative-to="$csproj_dir" "$SEARCH_DIR_PARENT")
  NEW_BASE_PATH="${rel_up//\//\\}\\build\\extensions"

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
