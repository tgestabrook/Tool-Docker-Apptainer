#!/bin/bash

# Check for required argument
if [ -z "$1" ]; then
  echo "Usage: $0 <search_directory>"
  exit 1
fi

SEARCH_DIR="$1"

# Desired values
APPEND_FRAMEWORK="false"
GENERATE_RUNTIME="true"

# Find all .csproj files recursively
find "$SEARCH_DIR" -type f -name "*.csproj" | while read -r csproj_file; do
  echo "Processing $csproj_file"

  # Update GenerateRuntimeConfigurationFiles (or add if missing)
  if xmlstarlet sel -t -v "//GenerateRuntimeConfigurationFiles" "$csproj_file" >/dev/null 2>&1; then
    xmlstarlet ed -L -u "//GenerateRuntimeConfigurationFiles" -v "$GENERATE_RUNTIME" "$csproj_file"
    echo " - Set GenerateRuntimeConfigurationFiles = $GENERATE_RUNTIME"
  else
    xmlstarlet ed -L \
      -s "//PropertyGroup[1]" -t elem -n GenerateRuntimeConfigurationFiles -v "$GENERATE_RUNTIME" \
      "$csproj_file"
    echo " - Added GenerateRuntimeConfigurationFiles = $GENERATE_RUNTIME"
  fi

  # Update AppendTargetFrameworkToOutputPath (or add if missing)
  if xmlstarlet sel -t -v "//AppendTargetFrameworkToOutputPath" "$csproj_file" >/dev/null 2>&1; then
    xmlstarlet ed -L -u "//AppendTargetFrameworkToOutputPath" -v "$APPEND_FRAMEWORK" "$csproj_file"
    echo " - Set AppendTargetFrameworkToOutputPath = $APPEND_FRAMEWORK"
  else
    xmlstarlet ed -L \
      -s "//PropertyGroup[1]" -t elem -n AppendTargetFrameworkToOutputPath -v "$APPEND_FRAMEWORK" \
      "$csproj_file"
    echo " - Added AppendTargetFrameworkToOutputPath = $APPEND_FRAMEWORK"
  fi

done

