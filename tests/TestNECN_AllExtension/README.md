This is a simple test scenario adapted from the PNET scenario created by Clement Hardy to test if the Docker image for LANDIS-II v8 resulting from the corresponding Dockerfile can run properly. Instead of PNET, it uses NECN as the succession library.

## Two scenario files, one set of inputs

| File | Used by | Difference |
| ---- | ------- | ---------- |
| `scenario.txt` | not currently run by any image build | all extensions enabled |
| `scenario_UCLv2.txt` | `landis-ii-v8-uclv2-release` | runs Biomass Harvest alone; Dynamic Fuel System, Dynamic Fire System, Magic Harvest, Linear Wind, Climate BDA, Land Use Plus, Output Biomass-by-Age, Local Habitat Output, Wildlife Habitat Output and Output-PnET commented out |

The inputs are shared, so a change to the inputs affects both runs.

Note that `scenario_UCLv2.txt` is more conservative than it needs to be: it dates from when
the UCLv2 image shipped fewer extensions, and Dynamic Fuel System, Dynamic Fire System,
Magic Harvest and Output-PnET have since been added to that image. They are exercised by
[`../TestPnET_AllExtension/scenario_UCLv2.txt`](../TestPnET_AllExtension/scenario_UCLv2.txt)
instead.

## Running it manually

```sh
docker run --rm -v "$PWD":/work -w /work ghcr.io/for-cast/landis-ii-v8-uclv2-release:main \
  /bin/sh -c "dotnet \$LANDIS_CONSOLE scenario_UCLv2.txt"
```
