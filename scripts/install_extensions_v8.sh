#!/bin/bash

set -e

## Validate input
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <extensions.yaml> <landis_directory> [plug-in|tool]"
  exit 1
fi

YAML_FILE="$1"
LANDIS_DIR="$2"
## optional: the entry `type` to process (see below). Plug-ins by default; tools
## are built in a separate, later pass (see the UCL2 Dockerfile).
PASS_TYPE="${3:-plug-in}"

if [[ "$PASS_TYPE" != "plug-in" && "$PASS_TYPE" != "tool" ]]; then
  echo "Error: unknown entry type '$PASS_TYPE' (expected plug-in or tool)" 1>&2
  exit 1
fi

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
  ## optional: name of a hand-maintained .csproj in extension_files/ to use for
  ## this entry (Clément's extensions only). Lets one build select a variant
  ## (e.g. a UCLv2 .csproj) without disturbing the basename-matched default the
  ## other release builds rely on. Absent -> "" (fall back to basename match).
  csproj_override=$(yq eval ".[$i].csproj // \"\"" "$YAML_FILE")
  ## optional: `type: tool` marks a stand-alone program that is built here but is
  ## not a plug-in (the Forest Product Sector Module): it is cloned in full, built
  ## into a temporary directory, installed in build/Release without registration,
  ## and not seen by `add_console_csproj_dlls.sh`. Absent -> "plug-in".
  ext_type=$(yq eval ".[$i].type // \"plug-in\"" "$YAML_FILE")

  if [[ -z "$repo" || -z "$org" || -z "$commit" ]]; then
    echo "Error parsing $YAML_FILE" 1>&2
    exit 1
  fi

  if [[ "$ext_type" != "plug-in" && "$ext_type" != "tool" ]]; then
    echo "Error: unknown type '$ext_type' for '$repo' in $YAML_FILE" 1>&2
    exit 1
  fi

  ## only the entries of this pass's type
  if [[ "$ext_type" != "$PASS_TYPE" ]]; then
    continue
  fi

  ## Clone repo using sparse checkout of specific commit
  ## (attempt to set sparse paths and continue even if some don't exist)
  echo "Cloning $org/$repo at commit $commit with sparse checkout ..."

  repo_path="$LANDIS_CORE_DIR/$repo"
  url="https://github.com/$org/$repo.git"

  ## tools are cloned in full: FPSM keeps its sources at the repo root and in
  ## `utility/`, outside SPARSE_PATHS, and its examples in `deploy/examples/`
  if [[ "$ext_type" == "tool" ||
        "$repo" == "LANDIS-II-Forest-Roads-Simulation-extension" ||
        "$repo" == "LANDIS-II-Magic-Harvest" ]]; then
    git clone "$url" "$repo_path"
  else
    git clone --filter=blob:none --no-checkout "$url" "$repo_path"
    git -C "$repo_path" sparse-checkout init --cone --sparse-index

    git -C "$repo_path" sparse-checkout set "${SPARSE_PATHS[@]}"
  fi

  git -C "$repo_path" fetch --depth=1 origin "$commit"
  git -C "$repo_path" checkout "$commit"

  ## Fix .csproj: use a hand-maintained override when a `csproj:` YAML entry
  ## names one, otherwise patch the repo's own .csproj with the update scripts.
  echo "Fixing .csproj files in $repo_path ..."
  ext_csproj_file="$(find "$repo_path" -type f -name "*.csproj" -print -quit)"

  if [[ -n "$csproj_override" ]]; then
    override_csproj="$LANDIS_DIR/extension_files/$csproj_override"
    if [[ ! -f "$override_csproj" ]]; then
      echo "Error: .csproj override '$override_csproj' for '$repo' not found" 1>&2
      exit 1
    fi
    cp "$override_csproj" "$ext_csproj_file"
  elif [[ "$ext_type" == "tool" ]]; then
    ## HintPaths only: a tool keeps its own output settings and is built into a
    ## temporary directory (below), never into build/extensions
    "$LANDIS_DIR/scripts/update_csproj_hintpaths.sh" "$repo_path"
  else
    "$LANDIS_DIR/scripts/update_csproj_misc.sh" "$repo_path"
    "$LANDIS_DIR/scripts/update_csproj_hintpaths.sh" "$repo_path"
    "$LANDIS_DIR/scripts/update_csproj_outputpaths.sh" "$repo_path"
  fi

  ## Remove any .sln files as these don't help the builds
  find "$repo_path" -type f -name "*.sln" -exec rm -v {} +

  ## With EXT_DROP_SHADOWING_DLLS=true (set by the UCLv2 Dockerfile), delete the
  ## extension's committed copy of any DLL that build/extensions already holds
  ## (support libraries, extensions built earlier). An SDK-style .csproj takes
  ## every file under its directory as a `None` item, and MSBuild resolves a
  ## reference from those files ({CandidateAssemblyFiles}) before its HintPath,
  ## so a committed `lib/*.dll` is compiled against instead of the
  ## build/extensions copy, and then copied over it (and below to build/Release).
  ## It applies to `type: tool` entries too: a tool is built into a temporary
  ## directory, so nothing is copied over, but it would still compile against
  ## the committed copy and then run against the build/Release one.
  ## The UCLv1 images leave it unset: the Forest Roads and Magic Harvest .csproj
  ## files they use (extension_files/) take some references only from the repos'
  ## committed `packages/` folders.
  if [[ "${EXT_DROP_SHADOWING_DLLS:-false}" == "true" ]]; then
    find "$repo_path" -name .git -prune -o -type f -name "*.dll" -print |
      while IFS= read -r dll; do
        if [[ -f "$LANDIS_EXT_DIR/$(basename "$dll")" ]]; then
          echo "$repo: removing committed ${dll#"$repo_path"/} (build/extensions has $(basename "$dll"))" |
            tee -a "$EXT_LOG_FILE"
          rm "$dll"
        fi
      done
  fi

  ## Build the extension and add to the extension registry
  ext_csproj_name=$(xmlstarlet sel -t -v "//AssemblyName" "$ext_csproj_file")
  ext_src_path=$(dirname "$ext_csproj_file")

  build_args=()
  if [[ "$ext_type" == "tool" ]]; then
    tool_out=$(mktemp -d)
    build_args=(-o "$tool_out")
  fi

  dotnet build "$ext_src_path" -c Release "${build_args[@]}" | tee -a "$EXT_LOG_FILE"

  ## fail fast on a failed extension build: the pipe to `tee` masks dotnet's
  ## exit code (the pipeline returns tee's 0), so `set -e` never trips and a
  ## broken extension would be registered with no .dll. Check PIPESTATUS.
  build_status=${PIPESTATUS[0]}
  if [ "$build_status" -ne 0 ]; then
    echo "Error: 'dotnet build' failed for extension '$repo' (exit $build_status); aborting." 1>&2
    exit "$build_status"
  fi

  ## append extension dependencies to the logfile for debugging
  dotnet list "$ext_csproj_file" package | tee -a "$EXT_LOG_FILE"

  ## install a tool without registering it: only its assembly and runtimeconfig go
  ## to build/Release, beside the support libraries it loads (with no deps.json,
  ## the .NET host resolves them from the app directory). build/Release is left
  ## otherwise untouched: the tool pass runs after the console rebuild, whose DLLs
  ## the image ships.
  if [[ "$ext_type" == "tool" ]]; then
    cp "$tool_out/$ext_csproj_name.dll" "$tool_out/$ext_csproj_name.runtimeconfig.json" "$LANDIS_REL_DIR/"
    rm -rf "$tool_out"

    ## build gate: FPSM's shipped examples, run from build/Release, must reproduce
    ## their committed output, as in FPSM's own CI (`.github/workflows/examples.yml`)
    if [[ "$repo" == "Extension-Forest-Product-Sector" ]]; then
      gate_status=0
      for ex in "$repo_path"/deploy/examples/*/; do
        name=$(basename "$ex")
        cfg=$(basename "$(ls "$ex"FPSM_*.txt)")
        work=$(mktemp -d)
        cp "$ex"log_Flux*.csv "$ex$cfg" "$work/"

        echo "FPSM example $name ($cfg) ..."
        (cd "$work" && dotnet "$LANDIS_REL_DIR/$ext_csproj_name.dll" "$cfg")

        for out in FPS_log.txt FPS_raw_out.csv FPS_test_out.csv; do
          [ -e "$ex$out" ] || continue
          if diff -q "$ex$out" "$work/$out" >/dev/null; then
            echo "  match: $out"
          else
            echo "Error: FPSM example $name: $out differs from the committed output" 1>&2
            diff "$ex$out" "$work/$out" | head -25 1>&2
            gate_status=1
          fi
        done
        rm -rf "$work"
      done
      if [ "$gate_status" -ne 0 ]; then
        exit 1
      fi
    fi

    rm -rf "$repo_path"
    continue
  fi

  ## copy Defaults for specific extensions
  if [[ "$repo" == "Extension-PnET-Succession" ]]; then
    cp -a "$repo_path/deploy/Defaults" "$LANDIS_REL_DIR/Defaults"
  fi

  ## find the extension's registration txt file. possible locations are:
  ## - `deploy/current/`
  ## - `deploy/install/`
  ## - `Deploy/Installation Files/plug-ins-installer-files`
  ## Only files declaring `LandisData Extension` count: installer folders can also
  ## hold licence texts (e.g. SOSIEL Harvest's `SHE LGPL.txt` sorts after `SHE 2.txt`).
  ext_txt_file=$(find "$repo_path" -type f -name "*.txt" \( -path "*/deploy/current/*" -o -path "*/[Dd]eploy/[Ii]nstall*/*" \) -print0 \
    | while IFS= read -r -d '' file; do
      grep -qiE 'LandisData[[:space:]]+"?Extension"?' "$file" || continue
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
