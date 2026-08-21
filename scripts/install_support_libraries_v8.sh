#!/bin/bash

set -e

## Install the PREBUILT support-library DLLs into the extensions directory.
##
## Distinct from `install_libraries_v8.sh`, which clones a library's source and
## runs `dotnet build` on it. The repos handled here ship compiled .dll files and
## no .csproj, so they are cloned and copied, never built. They are also applied
## BEFORE the extensions are compiled, because extensions reference these .dll
## files through HintPaths into the extensions directory -- which is why the pin
## cannot live in `libraries-v8-*.yaml` (built from source, and afterwards).

## Validate input
if [ $# -ne 2 ]; then
  echo "Usage: $0 <support-libraries.yaml> <landis_directory>"
  exit 1
fi

YAML_FILE="$1"
LANDIS_DIR="$2"

## Ensure these env vars match those in the Dockerfile!!
LANDIS_CORE_DIR="$LANDIS_DIR/Core-Model-v8-LINUX"
LANDIS_EXT_DIR="$LANDIS_CORE_DIR/build/extensions"

## Ensure the extensions directory exists: the core model must already be built,
## otherwise the DLLs would be copied somewhere nothing will look for them.
if [ ! -d "$LANDIS_EXT_DIR" ]; then
  echo "Error: directory $LANDIS_EXT_DIR not found" 1>&2
  exit 1
fi

## Get total number of repos to process
count=$(yq eval 'length' "$YAML_FILE")

for i in $(seq 0 $((count - 1))); do
  repo=$(yq eval ".[$i].repo" "$YAML_FILE")
  org=$(yq eval ".[$i].org" "$YAML_FILE")
  commit=$(yq eval ".[$i].commit" "$YAML_FILE")

  if [[ -z "$repo" || -z "$org" || -z "$commit" || "$commit" == "null" ]]; then
    echo "Error parsing $YAML_FILE" 1>&2
    exit 1
  fi

  ## Clone repo and checkout specific commit
  echo "Cloning $org/$repo at commit $commit ..."

  repo_path="$LANDIS_DIR/$repo"
  url="https://github.com/$org/$repo.git"

  ## Retry the clone. This is a plain network fetch in the middle of a long image
  ## build, so a transient failure throws away everything built so far. Observed on a
  ## fork build of 2026-08-18, 91 s into the clone:
  ##   fatal: unable to access '...': GnuTLS, handshake failed: The TLS connection
  ##   was non-properly terminated.
  ## while the very same step succeeded in the sibling matrix leg. A partial clone
  ## leaves the directory behind and would make the next attempt fail with "already
  ## exists", so remove it before retrying.
  clone_ok=false
  for attempt in 1 2 3; do
    if git clone "$url" "$repo_path"; then
      clone_ok=true
      break
    fi
    echo "  clone attempt $attempt/3 failed" 1>&2
    rm -rf "$repo_path"
    if [ "$attempt" -lt 3 ]; then
      sleep $((attempt * 10))
    fi
  done
  if [ "$clone_ok" != true ]; then
    echo "Error: failed to clone $url after 3 attempts" 1>&2
    exit 1
  fi

  git -C "$repo_path" checkout "$commit"

  ## Copy the prebuilt DLLs into place, then drop the clone (including its .git
  ## directory, which `mv repo/*` deliberately leaves behind).
  echo "Installing prebuilt support libraries from $repo ..."
  mv "$repo_path"/* "$LANDIS_EXT_DIR/"
  rm -rf "$repo_path"
done
