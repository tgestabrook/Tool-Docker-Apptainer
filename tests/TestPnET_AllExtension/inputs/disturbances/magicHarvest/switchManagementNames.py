# -*- coding: utf-8 -*-
"""
Choose which harvest prescription Magic Harvest re-initializes Biomass Harvest with.

Magic Harvest launches this once per its own Timestep, passing the current model
year as the only argument (see ProcessArguments in magic_harvest.txt; the
extension substitutes {timestep} with modelCore.CurrentTime).

Why this does not rename anything any more
------------------------------------------
It used to perform a three-way os.rename that swapped
biomass-harvest_SetUp_s2e1.txt with biomass-harvest_SetUp_s2e1_ALT.txt. Two
problems with that:

  * Both of those files are tracked in git, so simply running the scenario left
    the working tree modified.
  * The swap was unconditional, so which prescription was active depended on how
    many times the script had previously run in that directory. Magic Harvest
    has Timestep 10 and the scenario Duration is 50, so it fires five times --
    an odd number -- and the inputs were left swapped at the end of a run. A
    second run started in the same directory therefore began from the *other*
    prescription, which silently invalidates any comparison between two runs.

Instead this copies the chosen variant into an untracked working file. The two
tracked variants are never written, and the choice is derived from the year
rather than from accumulated state, so a run is repeatable and leaves the
repository clean.

The alternation the original was demonstrating is preserved: the ALT
prescription is active for the first Magic Harvest step, the original for the
second, and so on.
"""

import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

ORIGINAL = os.path.join(HERE, "biomass-harvest_SetUp_s2e1.txt")
ALTERNATE = os.path.join(HERE, "biomass-harvest_SetUp_s2e1_ALT.txt")

## magic_harvest.txt points HarvestExtensionParameterFile at this file. It is
## git-ignored and created here; it does not need to exist before the first
## Magic Harvest step, because the extension launches this script (PlugIn.cs
## line 116) before it loads the file (line 194).
ACTIVE = os.path.join(HERE, "biomass-harvest_SetUp_s2e1_ACTIVE.txt")

## Must match Timestep in magic_harvest.txt: the year passed in is a multiple of
## it, so year // STEP is the step number.
STEP = 10


def chosen_for(year):
    """ALT on odd Magic Harvest steps, the original on even ones.

    Mirrors the old behaviour, where the first fire left ALT in place, the
    second put the original back, and so on -- but computed from the year
    instead of from how many times this has run.
    """
    step = year // STEP
    return ALTERNATE if step % 2 == 1 else ORIGINAL


def main(argv):
    year = int(argv[1]) if len(argv) > 1 else 0
    source = chosen_for(year)
    shutil.copyfile(source, ACTIVE)
    print(
        "Magic Harvest year %d: harvest prescriptions from %s"
        % (year, os.path.basename(source))
    )


if __name__ == "__main__":
    main(sys.argv)
