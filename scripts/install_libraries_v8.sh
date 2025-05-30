#!/bin/bash

set -e

## Validate input
if [ $# -ne 2 ]; then
  echo "Usage: $0 <libraries.yaml> <landis_directory>"
  exit 1
fi

YAML_FILE="$1"
LANDIS_DIR="$2"

## Ensure these env vars match those in the Dockerfile!!
LANDIS_CORE_DIR="$LANDIS_DIR/Core-Model-v8-LINUX"
LANDIS_EXT_DIR="$LANDIS_CORE_DIR/build/extensions"
LANDIS_REL_DIR="$LANDIS_CORE_DIR/build/Release"

LANDIS_CONSOLE="$LANDIS_REL_DIR/Landis.Console.dll"
LANDIS_EXT_TOOL="$LANDIS_REL_DIR/Landis.Extensions.dll"

LIB_LOG_FILE="$LANDIS_DIR/build_libs.log"

## Ensure core model directory exists
if [ ! -d "$LANDIS_CORE_DIR" ]; then
  echo "Error: directory $LANDIS_CORE_DIR not found" 1>&2
  exit 1
fi

## create empty logfile
touch "$LIB_LOG_FILE"

## Get total number of repos to process
count=$(yq eval 'length' "$YAML_FILE")

for i in $(seq 0 $((count - 1))); do
  repo=$(yq eval ".[$i].repo" "$YAML_FILE")
  org=$(yq eval ".[$i].org" "$YAML_FILE")
  commit=$(yq eval ".[$i].commit" "$YAML_FILE")

  if [[ -z "$repo" || -z "$org" || -z "$commit" ]]; then
    echo "Error parsing $YAML_FILE" 1>&2
    exit 1
  fi

  ## Clone repo and checkout specific commit
  echo "Cloning $org/$repo at commit $commit ..."

  repo_path="$LANDIS_CORE_DIR/$repo"
  url="https://github.com/$org/$repo.git"

  git clone "$url" "$repo_path"
  git -C "$repo_path" checkout "$commit"

  ## Fix the paths etc. in the extension's .csproj file(s)
  echo "Fixing .csproj files in $repo_path ..."
  ext_csproj_file="$(find "$repo_path" -type f -name "*.csproj" -print -quit)"

  ## Replace .dll files for certain extensions
  if [[ "$repo" == "Library-Initial-Community" ]]; then
    rm "$LANDIS_EXT_DIR/Landis.Library.InitialCommunity.Universal.dll"
  elif [[ "$repo" == "Library-Universal-Cohort" ]]; then
    rm "$LANDIS_EXT_DIR/Landis.Library.UniversalCohorts-v1.dll"
  fi

  "$LANDIS_DIR/scripts/update_csproj_misc.sh" "$repo_path"
  "$LANDIS_DIR/scripts/update_csproj_hintpaths.sh" "$repo_path"
  "$LANDIS_DIR/scripts/update_csproj_outputpaths.sh" "$repo_path"

  ## Remove any .sln files as these don't help the builds
  find "$repo_path" -type f -name "*.sln" -exec rm -v {} +

  ## Build the extension and add to the extension registry
  ext_csproj_name=$(xmlstarlet sel -t -v "//AssemblyName" "$ext_csproj_file")
  ext_txt_file=$(find "$repo_path" -type f -name "*.txt" -path "*/[Dd]eploy/*" -print0 \
    | while IFS= read -r -d '' file; do
      printf '%s\0' "$(basename "$file"):::${file}"
    done \
  | sort -z \
  | awk -v RS='\0' -F ':::' '{print $2}' \
  | tail -n 1)
  ext_src_path=$(dirname "$ext_csproj_file")

  dotnet build "$ext_src_path" -c Release | tee -a "$LIB_LOG_FILE"

  ## append library dependencies to the logfile for debugging
  dotnet list "$ext_csproj_file" package | tee -a "$LIB_LOG_FILE"

  rm -rf "$repo_path"
done
