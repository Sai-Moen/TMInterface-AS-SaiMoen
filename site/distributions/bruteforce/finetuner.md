{{ site.header }}

# Finetuner

Formerly known as 'Finetune Location'.

Allows you to specify a certain location to be contained within, and to bruteforce towards a certain goal.
This could be position, rotation or speed (to get a specific value),
and many more combinations with modes/conditions are possible.

## Installation

### Finetuner

- [v2.1.1f](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/finetuner_v2.1.1f/finetuner.zip)
- [v2.1.1e](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/finetuner_v2.1.1e/finetuner.zip)
- [v2.1.1d](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/finetuner_v2.1.1d/finetuner.zip)
- [v2.1.1c](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/finetuner_v2.1.1c/finetuner.zip)
- [v2.1.1b](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/finetuner_v2.1.1b/finetuner.zip)

### Finetune Location

- [v2.1.1a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/finetune_location_v2.1.1a/finetune_location.zip)

- [v2.1.0a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/v2.1.0a_middle/finetune_location.zip)

- [dev_v2.0.1.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/pre_docs/finetune_location.as)
- [v2.0.1.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/finetune_location_v2.0.1.0/finetune_location.as)

## Guide

This plugin will register itself as a bruteforce mode.
Therefore, it can be found as a mode in the built-in bruteforce controller, under Optimization.

## Patch Notes

### v2.1.1f

- Added 'Glitching' condition (requested by igntuL).
- Fixed a bug where the wheel contact condition wouldn't accept runs with more wheel contact than specified.

### v2.1.1e

- Added combined printing mode for grouped targets.

### v2.1.1d

- Fixed a bug caused by not setting state at the start of evaluation.

### v2.1.1c

- Fixed a bug where the settings would not save when closing the game.
- Fixed a bug where diffs with custom Target Towards values would not be printed in the bruteforce terminal.
- Did some cleanup.

### v2.1.1b

- Renamed to 'Finetuner'.
- Completely rewrote the plugin
  (yes this is not SemVer at all, next TMInterface version I'm gonna switch to a sensible versioning scheme, I promise).

### v2.1.1a

- Fixed a bug where the UI would leak into the main window.

### v2.1.0a

- Groups, to quickly toggle a group of bounds.
- Wheel position bounds, as seen in Wheel Lineup and RammFinder.

### Dev v2.0.1.0

- Small fixes.

### v2.0.1.0

- Released.
