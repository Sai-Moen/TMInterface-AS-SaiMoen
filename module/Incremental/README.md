# Incremental
A procedural approach to input generation,
by SaiMoen.

### Terminology used, in simple terms

#### Plugin
This module, mostly used to refer to the general parts of it, though.

#### Script(s)
The modes the plugin offers (sd, wallhug).
This is mostly because python scripts were often standalone "scripts", so that naming stuck with me.

#### Starting Timerange
For each time in this range, the plugin will run the script as if the simulation just started, with the exact time parameters slightly changed.

#### Evaluation Timerange
This is the timerange where the script is allowed to modify inputs and check the state of the game. This is also where the script can eventually decide to advance to the next iteration by selecting a steering value, that will promptly be printed to the external console.

### Understanding the timeranges
Let's say this is a timerange representing a certain simulation from the start to the end of a replay (time goes left to right).

----------------|----|--------|-

The first vertical bar would be the start of the starting timerange,
the second would be the end of the starting timerange,
the third would be the end of the evaluation timerange.

The plugin would then go to the starting timerange and pick a time that falls within it. For technical reasons the plugin will always go from the last time to the first.

For each time in the starting timerange it will then run the script as if we were doing a simulation without a starting timerange. The time that was picked will be the start of the evaluation timerange, and the end of the evaluation timerange will be the "Maximum evaluation time" setting.

This process is repeated until either we run out of starting timerange times to test, or if the simulation is cancelled by pressing Escape with the external console in focus.

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

## SD Entry Helper (Experimental)
Found in bruteforce as an optimization target.
Optimizes for average local forwards force over a range of time.
This is a convenient metric to bruteforce for,
since the car's forward force is not influenced by speed when drifting.
This means that it mostly matters how good your SD is.

However it does have some problems with getting a stable SD,
so for now it will be marked as Experimental.
Until a better way of using it arises that sets up a nice entry for a non-bruteforce SD script,
velocity bruteforce might be better still.

## SD Railgun
Found in the Incremental validation handler.
Optimizes short-term steering values for speeddrifting.

### Classic
The original script, ported from Python.

Parameters:
- Seek (default 0.12 or 120ms)
  - Determines how far the algorithm looks ahead to check the speed for different steering values.
- Direction
  - Determines the direction that will be checked first
  - If the script still wants to try the other direction, then that will be checked instead.

## Wallhugger
Found in the Incremental validation handler.
Optimizes steering values to stay close to the walls.

### Classic
The original script, ported from Python.

Parameters:
- Seek (default 0.6 or 600ms)
  - Determines how far the algorithm looks ahead to check the collision for different steering values.
- Direction
  - Determines which way the wall is that needs to be hugged.
