# LANDIS-II v8 Docker Image (Linux Build)

This repository contains a Dockerfile and supporting scripts to build a fully functioning **LANDIS-II v8** environment with selected extensions compiled for **Linux**. This setup enables reproducible and portable forest landscape modeling, ideal for high-performance or cloud-based simulations.
This build uses the latest commits of each extension.

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
