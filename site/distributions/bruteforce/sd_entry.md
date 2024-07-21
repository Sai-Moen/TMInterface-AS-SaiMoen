{{ site.header }}

# SD Entry

Bruteforces a speedslide entry.

## Installation

- [v2.1.0a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/v2.1.0a_middle/sd_entry.zip)

- [v2.0.1.0]() (Unavailable)

## Guide

Set the time-from and time-to settings such that they coincide with the speedslide entry.
These two settings are the 'evaluation timeframe' of this plugin.

Contrary to most bruteforce modes,
it is not inefficient to (partially) overlap these evaluation timeframe settings with the input modification timeframe.
This is because this plugin cannot get an improvement at an arbitrary time in the evaluation timeframe.

## Patch Notes

### v2.1.0a

- Replaced PrefixVar with PREFIX constant.
- Replaced references with handles where possible.
- Miscellaneous refactoring.

### v2.0.1.0

- Separated from Incremental, now a standalone plugin.
