# Docker-LANDIS-II-v7-release

This image closely follows the original `Clean_Docker_LANDIS-II_7_AllExtensions` image with the following enhancements:

- places the LANDIS-II code at `/opt/landis-ii` instead of `/bin/LANDIS_Linux`,
  because `/opt` is the standard location for software not provided via the OS package manager;
- extension repos and commit SHAs are recorded in a shared `extensions-v7-release.yaml` file,
  rather than in the Dockerfile, which should be easier to update and maintain going forward;
- likewise, library repos and commit SHAs are recorded in a shared `libraries-v7-release.yaml` file,
  rather than in the Dockerfile, which should be easier to update and maintain going forward;
- install additional libraries before installing extensions;
- use single commit for ForCS 3.1;
- uses shared versions of the Forest Roads and Magic Harvest extensions' `.csproj` files,
  located in the `extension_files_v7/` directory;
- rewrote and simplified various installation scripts to use `bash`;
  these are shared in the `scripts/` directory and can be used directly with other image 'flavours';
  - uses `yq` to parse yaml files in bash;
  - uses `xmlstarlet` to parse and edit XML in the `.csproj` files;
- shared tests are copied from the `tests/` directory and run as part of the build process;

## Build the image

### Linux (bash)

```shell
cd ~/Tool-Docker-Apptainer

docker build . \
  -f Docker-LANDIS-II-v7-release/Dockerfile \
  -t landis-ii-7-release:release
```

### Windows (Powershell)

```shell
cd ~/Tool-Docker-Apptainer

docker build . `
  -f Docker-LANDIS-II-v7-release/Dockerfile `
  -t landis-ii-7-release:release
```

## Run a container

### Interactive container

#### Linux (bash)

```shell
docker run -it \
  --cpus=4 \
  --memory=64g \
  --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder \
  --name landis01 \
  landis-ii-7-release:release
```

#### Windows (Powershell)

```shell
docker run -it `
  --cpus=4 `
  --memory=64g `
  --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder `
  --name landis01 `
  landis-ii-7-release:release
```

### Non-interactive container

E.g., run a single LANDIS-II simulation

#### Linux (bash)

```shell
docker run \
  --cpus=4 \
  --memory=64g \
  --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder \
  --name landis01 \
  landis-ii-7-release:release /bin/sh -c "cd /scenarioFolder && dotnet $LANDIS_CONSOLE scenario.txt"
```

#### Windows (Powershell)

```shell
docker run `
  --cpus=4 `
  --memory=64g `
  --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder \
  --name landis01 `
  landis-ii-7-release:release /bin/sh -c "cd /scenarioFolder && dotnet $LANDIS_CONSOLE scenario.txt"
```

