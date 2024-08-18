{{ site.header }}

# Incremental

A collection of 'modes' that work incrementally from a start time to an end time,
instead of the bruteforce way where it indefinitely picks random times to modify.

## Installation

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

## Guide

### Modes

#### SD Railgun

This is the SD mode.

##### Classic

There used to be a classic sub-mode for this mode, but it was removed (in case you were wondering).

##### Normal

The normal sub-mode will automatically determine direction, and you just need to set a certain lookahead time.
The default lookahead time is 120ms, which should always work given a decent enough setup.

#### Wallhugger

This is the wall-hugging mode.

##### Classic

The classic sub-mode is what the python version more or less did.

##### Normal

The normal sub-mode is an experiment,
that tries to automatically determine how far to look ahead based on how long it takes to reach the wall.

#### Simplify Inputs

This is an input simplifier/smoother.
Note: you most likely want to set the evaluation timeframe to 0.0-0.0 (Eval Min = 0 and Eval Max = 0),
to simplify all inputs.

### Understanding the timeranges

#### Starting Timerange

For each time in this range, the plugin will run the script as if the simulation just started,
with the exact time parameters slightly changed.

#### Evaluation Timerange

This is the timerange where the script is allowed to modify inputs and check the state of the game.
This is also where the script can eventually decide to advance to the next iteration by selecting a steering value,
that will be printed to the external console.

#### Example

Let's say this is a timerange representing a certain simulation from the start to the end of a replay (time goes left to right).

----------------|----|--------|-

The first vertical bar would be the start of the starting timerange,
the second would be the end of the starting timerange,
the third would be the end of the evaluation timerange.

The plugin would then go to the starting timerange and pick a time that falls within it.
For technical reasons the plugin will always go from the last time to the first.

For each time in the starting timerange,
it will then run the script as if we were doing a simulation without a starting timerange.
The time that was picked will be the start of the evaluation timerange,
and the end of the evaluation timerange will be the "Maximum evaluation time" setting.

This process is repeated until either we run out of starting timerange times to test,
or if the simulation is cancelled by pressing Escape with the external console in focus.

### Main Parameters

- Evaluate Timerange?
  - Determines whether to evaluate a multitude of starting times.
- (If Evaluate Timerange)
  - Minimum starting time
    - Determines the start of the starting timerange.
  - Maximum starting time
    - Determines the end of the starting timerange.
- (Else)
  - Minimum evaluation time
    - Determines the start of the evaluation timerange.
- Maximum evaluation time
  - Determines the end of the evaluation timerange.

## Patch Notes

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
