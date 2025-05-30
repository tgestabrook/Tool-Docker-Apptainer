#!/bin/bash

## Check for required argument
if [ -z "$1" ]; then
  echo "Usage: $0 <landis_directory>"
  exit 1
fi

LANDIS_DIR="$1"

if [ ! -d "$LANDIS_DIR" ]; then
  echo "Error: directory $LANDIS_DIR not found" 1>&2
  exit 1
fi

## Ensure these env vars match those in the Dockerfile!!
LANDIS_CORE_DIR="$LANDIS_DIR/Core-Model-v8-LINUX"
LANDIS_EXT_DIR="$LANDIS_CORE_DIR/build/extensions"
LANDIS_EXT_DIR_REL="../../build/extensions"

CONSOLE_CSPROJ="$LANDIS_CORE_DIR/Tool-Console/src/Console.csproj"

## Check if DLL directory exists
if [ ! -d "$LANDIS_EXT_DIR" ]; then
  echo "Error: Directory $LANDIS_EXT_DIR does not exist."
  exit 1
fi

## Check if Console.csproj file exists
if [ ! -f "$CONSOLE_CSPROJ" ]; then
  echo "Error: File $CONSOLE_CSPROJ does not exist."
  exit 1
fi

## Extract existing references from the Console.csproj file
existing_refs=$(xmlstarlet sel -t -m "//Reference" -v "@Include" -n "$CONSOLE_CSPROJ" | \
  sed 's/\.dll$//')

## Modify existing Metadata reference to include the .dll extension
xmlstarlet ed -L \
  -u "//Reference[@Include='Landis.Library.Metadata-v2']/HintPath" \
  -v "$LANDIS_EXT_DIR_REL/Landis.Library.Metadata-v2.dll" \
  "$CONSOLE_CSPROJ"

echo "Updated existing references in $CONSOLE_CSPROJ."

## Define DLLs to avoid referencing (because already referenced?)
avoid_dlls=(
  "Landis.Console"
  "Landis.Core"
  "Landis.Extensions.Dataset"
  "Landis.Landscapes"
  "Landis.Library.Parameters"
  "Landis.Raster"
  "Landis.RasterIO.Gdal" ## want the linux version only
  "Landis.SpatialModeling"
  "Landis.Utilities"
  "SiteHarvest"
)

## Find relevant DLL files in the specified directory
new_refs=()
for dll in "$LANDIS_EXT_DIR"/*.dll; do
  dll_name=$(basename "$dll" .dll)

  ## Skip DLLs that are in the avoid list or already referenced
  if [[ " ${avoid_dlls[@]} " =~ " ${dll_name} " ]] || \
     [[ " ${existing_refs[@]} " =~ " ${dll_name} " ]]; then
    continue
  fi

  ## Add new reference
  new_refs+=("$dll_name")
done

## If there are new references, insert them into the Console.csproj file
if [ ${#new_refs[@]} -gt 0 ]; then
  ## Create XML snippets for new references
  for ref in "${new_refs[@]}"; do
    ## Add the Reference and HintPath elements to the file
    xmlstarlet ed -L \
      -s "/Project" -t elem -n "ItemGroup" -v "" \
      -s "//ItemGroup[last()]" -t elem -n "Reference" -v "" \
      -s "//ItemGroup[last()]/Reference" -t attr -n "Include" -v "$ref" \
      -s "//ItemGroup[last()]/Reference" -t elem -n "HintPath" -v "$LANDIS_EXT_DIR_REL/$ref.dll" \
      "$CONSOLE_CSPROJ"
  done

  echo "Added ${#new_refs[@]} new references to $CONSOLE_CSPROJ."
else
  echo "No new references to add."
fi
