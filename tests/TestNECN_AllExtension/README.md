This is a simple test scenario adapted from the PNET scenario created by Clement Hardy to test if the Docker image for LANDIS-II v8 resulting from the corresponding Dockerfile can run properly. Instead of PNET, it uses NECN as the succession library.

## Two scenario files, one set of inputs

| File | Used by |
| ---- | ------- |
| `scenario.txt` | not currently run by any image build |
| `scenario_UCLv2.txt` | `landis-ii-v8-uclv2-release` |

`scenario_UCLv2.txt` runs the subset of extensions the UCLv2 image ships; each entry it
leaves commented out says why, so keep those comments up to date as extensions get their
UCL v2 updates. The inputs are shared, so a change to the inputs affects both runs.

Note that neither scenario runs Output-PnET: it reads PnET site variables and therefore
cannot run under NECN Succession at all (it NREs in `Output.PnET.ISiteVar.GetIsiteVar`).
[`../TestPnET_AllExtension`](../TestPnET_AllExtension) covers that extension.

## Running it manually

```sh
docker run --rm -v "$PWD":/work -w /work ghcr.io/for-cast/landis-ii-v8-uclv2-release:main \
  /bin/sh -c "dotnet \$LANDIS_CONSOLE scenario_UCLv2.txt"
```
