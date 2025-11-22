{{ site.header2 }}

# Incremental

A collection of 'modes' that work incrementally from a start time to an end time,
instead of the bruteforce way where it indefinitely picks random times to modify.

## Installation

- [v3.0.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.0.0/incremental.zip)

- [v2.1.1j](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1j/incremental.zip)
- [v2.1.1i](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1i/incremental.zip)
- [v2.1.1h](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1h/incremental.zip)
- [v2.1.1g](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1g/incremental.zip)
- [v2.1.1f](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1f/incremental.zip)
- [v2.1.1e](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1e/incremental.zip)
- [v2.1.1d](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1d/incremental.zip)
- [v2.1.1c](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1c/incremental.zip)
- [v2.1.1b](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1b/incremental.zip)
- [v2.1.1a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.1a/incremental.zip)

- [v2.1.0b](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.0b/incremental.zip)
- [v2.1.0a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.1.0a/incremental.zip)

- [v2.0.1.1](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v2.0.1.1/incremental.zip)
- [v2.0.1.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/pre_docs/incremental.zip)

- [v2.0.0.5]() (Unavailable)
- [v2.0.0.4](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_4/Incremental.zip)
- [v2.0.0.3]() (Unavailable)
- [v2.0.0.2]() (Unavailable)
- [v2.0.0.1](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/v2.0.0.1/Incremental.zip)

- [v1.5.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/v1.5.0/Incremental.zip)

## Patch Notes

### v3.0.0

- Added quality SD.
- Moved run-mode bruteforce to the settings page itself.
- Removed the '(i)' tooltips in favor of just a tooltip on hover of the setting itself.

### v2.1.1j

- Fixed bug with brake minimization (only in run mode for now).
- Changed behavior of run-mode BF to unload currently loaded CommandList instead of setting `execute_commands`.

### v2.1.1i

- Fixed rewind bugs.
- Moved functionalities specific to run-mode into a settings page.

### v2.1.1h

- Note: this is an experimental version.
- Added run-mode bruteforce.

### v2.1.1g

- Fixed a bug with savestate mode where savestates would not load correctly under certain conditions.
- Cleaned up User Interface.

### v2.1.1f

- Fixed some bugs (info not showing, unexpected evaluation timerange mode running).

### v2.1.1e

- Rewrote core simulation logic, 20%-25% faster.
- Created biggest violation of Semantic Versioning in the history of mankind.

### v2.1.1d

- Added strategy order and brake minimization to the Input Simplifier mode.

### v2.1.1c

- Added a new strategy to the Input Simplifier mode that allows you to control the magnitude of air inputs.

### v2.1.1b

- Fixed problems with the Input Simplifier mode related to input filling/unfilling.

### v2.1.1a

- Added Input Simplifier mode.
- Added Wallhug Normal sub-mode.

### v2.1.0b

- Removed SD Classic sub-mode.
- Improved SD Normal sub-mode.
- Info now prints km/h instead of m/s.
- Eval no longer tries to save old inputs when cleaning up.

### v2.1.0a

- Now saves all inputs to result.txt (or whatever you set that setting to in bruteforce).
- Added temporary workaround for input issues.

### v2.0.1.1

- Added SaveState support.

### v2.0.1.0

- Small fixes.
- Move `SD Entry` to a separate plugin.

### v2.0.0.5

- Added Starting Timerange.
- Added a README file.

### v2.0.0.4

- Added Wallhugger Classic sub-mode.

### v2.0.0.3

- Start using external console to print information.
- Add Misc header with an option to show information during simulation.

### v2.0.0.2

- Added SD Entry Helper.

### v2.0.0.1

- Added SD Railgun Classic sub-mode.

### v1.5.0

Note: this is me experimenting with AngelScript TMInterface plugins before their public release.

- Released initial version.
