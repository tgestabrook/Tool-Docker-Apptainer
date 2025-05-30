#!/bin/bash

set -e

## Validate input
if [ $# -ne 2 ]; then
  echo "Usage: $0 <extensions.yaml> <landis_directory>"
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

EXT_LOG_FILE="$LANDIS_DIR/build_exts.log"

## Sparse-checkout these paths; we need the following:
##   source code:
##   - "src/"
##
##   extension registraion files
##   - "deploy/current/"
##   - "deploy/installer/"
##   - "Deploy/Installation Files/plug-ins-installer-files/"
##
##   default praameter files:
##   - "deploy/Defaults/"
SPARSE_PATHS=(
  "deploy/current"
  "deploy/Defaults"
  "deploy/installer"
  "Deploy/Installation Files/plug-ins-installer-files"
  "src"
)

## Ensure needed directories exist
if [ ! -d "$LANDIS_CORE_DIR" ]; then
  echo "Error: directory $LANDIS_CORE_DIR not found" 1>&2
  exit 1
fi

## create empty logfile
touch "$EXT_LOG_FILE"

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

  ## Clone repo using sparse checkout of specific commit
  ## (attempt to set sparse paths and continue even if some don't exist)
  echo "Cloning $org/$repo at commit $commit with sparse checkout ..."

  repo_path="$LANDIS_CORE_DIR/$repo"
  url="https://github.com/$org/$repo.git"

  if [[ "$repo" == "LANDIS-II-Forest-Roads-Simulation-extension" ||
        "$repo" == "LANDIS-II-Magic-Harvest" ]]; then
    git clone "$url" "$repo_path"
  else
    git clone --filter=blob:none --no-checkout "$url" "$repo_path"
    git -C "$repo_path" sparse-checkout init --cone --sparse-index

    git -C "$repo_path" sparse-checkout set "${SPARSE_PATHS[@]}"
  fi

  git -C "$repo_path" fetch --depth=1 origin "$commit"
  git -C "$repo_path" checkout "$commit"

  ## Fix the paths etc. in the extension's .csproj file(s);
  ##  - except for Clément's extensions (which are structured differently) so use custom files.
  echo "Fixing .csproj files in $repo_path ..."
  ext_csproj_file="$(find "$repo_path" -type f -name "*.csproj" -print -quit)"

  if [[ "$repo" == "LANDIS-II-Forest-Roads-Simulation-extension" ||
        "$repo" == "LANDIS-II-Magic-Harvest" ]]; then
    cp "$LANDIS_DIR/extension_files/$(basename "$ext_csproj_file")" "$ext_csproj_file"
  else
    "$LANDIS_DIR/scripts/update_csproj_misc.sh" "$repo_path"
    "$LANDIS_DIR/scripts/update_csproj_hintpaths.sh" "$repo_path"
    "$LANDIS_DIR/scripts/update_csproj_outputpaths.sh" "$repo_path"
  fi

  ## Remove any .sln files as these don't help the builds
  find "$repo_path" -type f -name "*.sln" -exec rm -v {} +

  ## Build the extension and add to the extension registry
  ext_csproj_name=$(xmlstarlet sel -t -v "//AssemblyName" "$ext_csproj_file")
  ext_src_path=$(dirname "$ext_csproj_file")

  dotnet build "$ext_src_path" -c Release | tee -a "$EXT_LOG_FILE"

  ## append extension dependencies to the logfile for debugging
  dotnet list "$ext_csproj_file" package | tee -a "$EXT_LOG_FILE"

  ## copy Defaults for specific extensions
  if [[ "$repo" == "Extension-PnET-Succession" ]]; then
    cp -a "$repo_path/deploy/Defaults" "$LANDIS_REL_DIR/Defaults"
  fi

  ## find the extension's registration txt file. possible locations are:
  ## - `deploy/current/`
  ## - `deploy/install/`
  ## - `Deploy/Installation Files/plug-ins-installer-files`
  ext_txt_file=$(find "$repo_path" -type f -name "*.txt" \( -path "*/deploy/current/*" -o -path "*/[Dd]eploy/[Ii]nstall*/*" \) -print0 \
    | while IFS= read -r -d '' file; do
      printf '%s\0' "$(basename "$file"):::${file}"
    done \
  | sort -z \
  | awk -v RS='\0' -F ':::' '{print $2}' \
  | tail -n 1)

  if [[ -z "$ext_txt_file" ]]; then
    all_ext_txt_files=$(find "$repo_path" -type f -name "*.txt")
    echo -e "Error finding extension's .txt registration file:\n$all_ext_txt_files" 1>&2
    exit 1
  fi

  echo "Registering $repo: adding $ext_txt_file"
  dotnet "$LANDIS_EXT_TOOL" add "$ext_txt_file"

  ## copy built files over to Release directory, because LANDIS-II reasons...

  # ext_dll="$ext_src_path/obj/Release/$ext_csproj_name.dll"
  # cp "$ext_dll" "$LANDIS_EXT_DIR/"
  find "$LANDIS_EXT_DIR" -type f -name "*.dll" -exec cp -a -- "{}" "$LANDIS_REL_DIR/" \;

  ## TODO: test the extension using the tests in the `testings/` directory

  rm -rf "$repo_path"
done
