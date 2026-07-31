This is a simple test scenario created by Clement Hardy to test if the Docker image for LANDIS-II v8 resulting from the corresponding Dockerfile can run properly.

I've tried to put as much extensions working at the same time as possible to try to detect potential conflicts between extensions and libraries.

## Two scenario files, one set of inputs

| File | Used by | Difference |
| ---- | ------- | ---------- |
| `scenario.txt` | `landis-ii-v8-release` (and the R / RStudio images) | all extensions enabled |
| `scenario_UCLv2.txt` | `landis-ii-v8-uclv2-release` | Linear Wind, Climate BDA, Land Use Plus, Local Habitat Output and Wildlife Habitat Output commented out |

Those five are commented out of the UCLv2 scenario because that image does not ship them:
all but Land Use Plus have no UCL v2 update upstream yet, and Land Use Plus is excluded
while its upstream UCL v2 migration is unfinished (see issue #59). Re-enable them there as
they get their updates. The inputs are shared, so a change to the inputs affects both runs.

Beyond confirming the extensions load, the UCLv2 run is what exercises
`Landis.Library.PnETCohorts-v2` rebuilt from its `UCL_update` branch: the copy shipped in
`Support-Library-Dlls-v8` is still the UCLv1 build (v2.1.1), so that image rebuilds the
library *before* compiling the extensions (see
[`libraries-v8-UCL2-prebuild.yaml`](../../libraries-v8-UCL2-prebuild.yaml)).

## Running it manually

```sh
docker run --rm -v "$PWD":/work -w /work ghcr.io/for-cast/landis-ii-v8-uclv2-release:main \
  /bin/sh -c "dotnet \$LANDIS_CONSOLE scenario_UCLv2.txt"
```
