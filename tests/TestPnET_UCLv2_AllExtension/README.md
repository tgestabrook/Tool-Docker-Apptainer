# TestPnET_UCLv2_AllExtension (UCLv2)

The PnET-Succession test scenario for the **`landis-ii-v8-uclv2-release`** (UCLv2) image.

It is a copy of [`../TestPnET_AllExtension`](../TestPnET_AllExtension) (Clement Hardy's
"as many extensions running at once as possible" scenario, used as the build gate for the
`landis-ii-v8-release` image), with the extensions that image ships but this one does not
commented out of `scenario.txt`:

| Extension | Why it is off here |
| --------- | ------------------ |
| Linear Wind | no UCLv2 update upstream |
| Climate BDA | no UCLv2 update upstream |
| Land Use Plus | upstream UCLv2 migration unfinished (see issue #59) |
| Local Habitat Output | no UCLv2 update upstream |
| Wildlife Habitat Output | no UCLv2 update upstream |

Everything else is unchanged, so the run still exercises PnET-Succession together with
Dynamic Fuel System, Dynamic Fire System, Magic Harvest, Biomass Harvest, Forest Roads
Simulation, Original Wind, Hurricane, and the biomass/cohort/PnET output extensions.

Beyond confirming the extensions load, this is the scenario that exercises
`Landis.Library.PnETCohorts-v2` rebuilt from its `UCL_update` branch: the copy shipped in
`Support-Library-Dlls-v8` is still the UCLv1 build (v2.1.1), so the image rebuilds the
library *before* compiling the extensions (see
[`libraries-v8-UCL2-prebuild.yaml`](../../libraries-v8-UCL2-prebuild.yaml)). Re-enable the
rows above as those extensions get their UCLv2 updates.

## Running it manually

```sh
docker run --rm -v "$PWD":/work -w /work ghcr.io/for-cast/landis-ii-v8-uclv2-release:main \
  /bin/sh -c "dotnet \$LANDIS_CONSOLE scenario.txt"
```
