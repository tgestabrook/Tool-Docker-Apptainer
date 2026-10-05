# TestSOSIEL_v8 (UCLv1)

A SOSIEL Harvest test scenario for the **`landis-ii-v8-release`** (UCLv1) image.

The inputs are the upstream
[Extension-SOSIEL-Harvest](https://github.com/LANDIS-II-Foundation/Extension-SOSIEL-Harvest)
repository's own `tests/Core8.0-SOSIEL2.0` example, taken at the commit this image pins
(`ed6f110`). It runs Biomass Succession, SOSIEL Harvest (mode 2, which applies Biomass Harvest
prescriptions chosen by SOSIEL agents), Dynamic Fuel System, Dynamic Fire System and Output Biomass.

Changes from upstream:

- `scenario_SHE.txt` is renamed `scenario.txt`, its `Duration` is cut from 200 to 20 years,
  and `RandomNumberSeed 1234` is uncommented;
- the two prescriptions in `input_BHE_SHE.txt` end at year 20 instead of 200
  (Biomass Harvest rejects an end year after the scenario's end);
- files the scenario doesn't read are left out (the Windows batch file, a sample log,
  `SOSIELHuman_FM1_rules.csv`, `Stand_Map.tiff`, and two output extensions' inputs that
  are commented out in the scenario).

## Harvest check

The Dockerfile asserts that `biomass-harvest-summary-log.csv` reports at least one harvested site,
so the build fails if SOSIEL Harvest loads but harvests nothing.
With this seed it harvests 9,318 sites at year 20 (none at year 10).

## Running it manually

```sh
docker run --rm --mount type=bind,src="$PWD",dst=/scenarioFolder \
  ghcr.io/landis-ii-foundation/landis-ii-v8-release:ubuntu-latest \
  /bin/sh -c "cd /scenarioFolder && dotnet \$LANDIS_CONSOLE scenario.txt"
```
