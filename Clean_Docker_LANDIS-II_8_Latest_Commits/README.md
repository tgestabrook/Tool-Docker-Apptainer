# LANDIS-II v8 Docker Image (Linux Build)

This image closely follows the original `Clean_Docker_LANDIS-II_8_AllExtensions` image with the following enhancements:

- uses the latest commits of each extension;
- adds and configures additional software components:
  - GitHub commandline tools;
  - miniconda3 environment;
  - [`tini`](https://github.com/krallin/tini) container init;
  - [`ttyd`](https://github.com/tsl0922/ttyd) for terminal sharing over the web;
  - [iRods](https://irods.org/);
  - `tmux`;
- custom user `user` and permissions;
- custom container `ENTRYPOINT` (see [entry.sh](entry.sh));

---

## Included Extensions

- Core Model v8
- Biomass Succession
- NECN Succession
- DGS Succession (GIPL + SHAW Libraries)
- Social-Climate-Fire
- Output Biomass
- Output Biomass Community
- Output Biomass Reclass
- Output Max Spp Age

## Build Instructions

To build the Docker image locally:

```bash
git clone https://github.com/LANDIS-II-Foundation/Tool-Docker-Apptainer.git
cd Clean_Docker_LANDIS-II_8_Latest_Commits
docker build -t landisii-v8 .
```

## Starting the container in detached mode and mount your input files
```bash
docker run -d --platform linux/amd64 -v path/to/inputs:/home/user/inputs landisii-v8

#list container names
docker container ls

#enter the container
docker exec -it container_name /bin/bash
```

## Running landis (assuming your scenario file is named "scenario.txt"
```bash
dotnet $console scenario.txt
```
