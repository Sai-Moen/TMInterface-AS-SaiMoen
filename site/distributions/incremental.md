{{ site.header2 }}

# Incremental

A collection of modes that incrementally build inputs in a given timerange,
unlike bruteforce, which indefinitely tries random changes on a run.

## Installation

- [v3.3.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.3.0/incremental.zip)

- [v3.2.1](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.2.1/incremental.zip)
- [v3.2.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.2.0/incremental.zip)

- [v3.1.2](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.1.2/incremental.zip)
- [v3.1.1](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.1.1/incremental.zip)
- [v3.1.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.1.0/incremental.zip)

- [v3.0.1](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/incremental_v3.0.1/incremental.zip)
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

## Guide

This guide gives a more in-depth explanation to all the settings than the tooltips provide.

### General

This section contains the most important core Incremental settings.

The basic idea of the time-related settings, is to set the bounds of time in which Incremental operates.
Additionally, there is the concept of 'iterations', which are not to be confused with bruteforce iterations.
Rather, an iteration in Incremental refers to a particular begin-end time pair.
With the 'single iteration' setting enabled, the settings are simplified to only specify one of those pairs.
Otherwise, the settings specify multiple pairs, which could be especially useful to try multiple starting times for an SD.

For example, suppose you wanted to try an SD from the times 15.29-15.41 to 17.66, on the second A01 SD.
With only a single iteration (which was the case on early Incremental versions),
you would need to run Incremental 13 separate times, and manually change the beginning time between each iteration.
With multiple iterations, this process is automated, and Incremental would do the following iterations:
(15.29-17.66, 15.30-17.66, ..., 15.40-17.66, 15.41-17.66).
To do this, you would need to set the iteration begin time to 15.29, iteration end time to 15.41, and the end time to 17.66.

As a side note, setting the end time to 0 will cause it to be set to the replay time when the evaluation starts.

After running all iterations, the best one is selected by the following properties (from more important to less important):
1. Finish time (if applicable)
2. Exit speed
3. Earlier beginning time (arbitrary tiebreaker, hopefully does not happen?)

Although the multiple iterations feature can be very useful for the SD Railgun mode,
it is questionable at best whether it is helpful for the SteerMax mode,
and the Input Simplifier mode force-enables the single iteration setting.

Last but not least, there is also an 'Evaluate Full Replay' setting.
This automatically makes Incremental use 0 for all evaluation times,
which will then cause the replay time to be used as the actual end time, as mentioned earlier.
This is mostly useful for the Input Simplifier mode, as the others usually require a more fine-tuned begin/end time.

### Modes

Incremental supports several modes, which all have their own ways of generating inputs to solve a particular problem.

#### Input Simplifier

The purpose of an input simplifier is to find inputs that may be easier to bruteforce, or just nicer to look at,
while still matching the actual run (i.e. the states of the car).

It does this by attempting several strategies:
- Turning Rate: in this strategy,
  the turning rate of the car is used to determine a steering value that effectively results in the same turning rate.
  This is a strategy that typically works on the ground.
- Sign-Magnitude: in this strategy, the sign of the steering input of the car is multiplied with a user-specified magnitude,
  to find a steering value.
  This is a strategy that typically works in the air.
- Removal: in this strategy, the previous steering value is used as the current value as well,
  which could then be 'unfilled' later.

It should be noted that it is not fully known under what exact conditions these strategies work or not, and why.
This is why these strategies are just guesses, and could be wrong on a particular tick.
There is a menu to specify in what order they are attempted.
In the worst case, the original steering value has to be used, if no strategy works.

To determine at what point a strategy has succeeded, we must look ahead from the input change time by some amount of time,
to check if it caused us to desync from the original run.
This is what the 'lookahead' setting specifies.
Lowering it will improve performance, but setting it too low will cause the result to no longer match the original run.
As of writing, the highest desync time offset I have seen is 260ms, so I would not recommend setting the lookahead below that,
though the default value of this setting is 400ms just to be safe.

An additional strategy, one that does not deal with steering inputs, is 'Minimize Brake'.
As the name implies, this strategy tries to turn every tick on which the brake is active, into a brake release instead.
Note that this could result in more brake inputs in total
(e.g. splitting one long brake press/rel into two short brake press/rel; adding two inputs).

#### SD Railgun

The purpose of the SD Railgun mode is to generate steering inputs for a SpeedDrift
(the 'Railgun' part is just a marketing term to set it apart from `speedslide_perfect`).

Originally, this mode exclusively used velocity to determine the best steering value.
At some point, the SD Quality was factored into this as well, so now the mode has two different possible metrics to use.
To decide between these, there is a 'quality threshold', which determines at what point quality is a good metric to use.
Specifically, if the difference between the best attempt's quality and the theoretical optimimum exceeds the threshold,
the velocity metric is used as a fallback.

Both metrics have their own 'lookahead' associated with them,
which determines after what amount of time the metric for a given steering value attempt is saved.
Setting it too high may accrue small speed losses over time due to the steering not being as aggressive as it could be,
though setting it too low could just lead to seemingly arbitrary inputs that do not achieve/maintain an SD.

It should be noted that this mode does not start an SD for you.
This is because an SD setup is quite map-specific, not just in the position/angle you begin with,
but also where you end up after the SD.
It may require some fine-tuning of the entry to get the desired SD, and bruteforcing the entry/exit could be helpful as well.

#### SteerMax

The purpose of the SteerMax mode is to generate steering inputs approaching as close to a particular steering value as possible,
while keeping to a set of constraints (e.g. speed requirements, not sliding).
This is particularly useful when doing a noslide and/or wallhug,
thus those use cases will be analyzed while explaining the settings.

There are three different kinds of 'lookahead strategies':
1. Absolute
  This is a strategy that works the most like the other Incremental modes, with just a fixed 'lookahead' setting.
2. Relative
  This is a strategy where the 'lookahead offset' is added to the time at which a constraint failed,
  to make the actual lookahead.
  Since this could lead to situations where the lookahead is infinitely long,
  there is a 'timeout' setting which determines at what time it can be assumed that the most optimal steering can be used.
3. Dynamic
  This is a strategy that can dynamically increase the lookahead,
  when the constraints cannot be avoided at the current lookahead.
  The lookahead starts at the 'base lookahead',
  and can at most increase by an amount of time specified by the 'max rollback' setting.
  The 'max rollback' setting mostly exists to stop execution when something happens that cannot be avoided,
  without destroying the inputs the mode found up to that point (by rolling back all the way to the start).
  The nice thing is that it does not have a performance impact if you set it higher,
  since lookahead is always minimized unless it must be higher to get past a certain point of the map.

For noslides, the dynamic lookahead with 20ms (0.02s) base lookahead works quite well.
For wallhugs, a low lookahead (less than 200ms (0.2s)) tends to lead to too aggressive steering,
followed by bouncing off the wall too much.
It is also not completely clear which of these strategies works best for wallhugging,
although it does not seem like there is much reason to use Dynamic,
since the base lookahead has to be increased significantly to make it work at all.
For simplicity you can use Absolute with a lookhead of 200ms-300ms,
though there is a caveat to this, as I will soon explain.

The 'steer towards' and 'steer away' settings determine the valid range of steering values,
and they specify the optimal and pessimal steering value, respectively.
For noslides, the full range is recommended (which can easily be entered with the 'Left' and 'Right' buttons).
For wallhugs, you could choose to set 'steer away' to zero as well ('Left' or 'Right' button, followed by 'Zero' button),
as countersteering during a wallhug is not a good sign anyway.

There is also something called 'steer offset',
which basically takes the best steering value and moves it closer to the 'steer away' value,
thus making the steering less aggressive.

There are three different kinds of 'steer offset strategies':
1. Off
  No steer offset will be applied.
2. Manual
  The given steer offset will be applied.
3. Automatic
  The steer offset will be determined by doing several runs of the iteration,
  to approach the lowest feasible value that does not lead to failure.
  Because the amount of retries to find this value might be high, it might take a long time to finish running.

For noslides, it is best to just leave this off.
For wallhugs, it is possible for the car to get too close to the wall,
such that steering towards it causes a front-wheel hit, yet steering away from it causes a back-wheel hit.
In this case the steering values will suddenly get closer to 0, followed by fullsteer when it gets far enough away again,
making the car bounce off the wall instead of hugging it.
In the worst case, it will just lead to the car crashing altogether.
The solution is to use a small steer offset (400-2000) to smooth out the wallhug.
Once a good setup has been reached, the Automatic strategy can be used to minimize the steer offset.
To address the caveat from earlier,
an alternative to a medium (e.g. 200ms) lookahead with steer offset would be a high (e.g. 600ms) lookahead without steer offset,
though this has worse results in the form of a strange 'stepping' of the steering values at certain times.

As for the constraint settings, they are the following:
- Max Speed Loss
  The cumulative speed loss allowed, compared to the peak speed.
- Max Speed Bleed
  The immediate speed loss allowed, compared to the speed on the previous tick,
  where negative values effectively specify a minimum acceleration.
- Ignore Speed Bleed while Gearing
  If the gearbox is not in the default state, it is probably maxing out and gearing,
  so by ignoring the speed bleed while this is happening,
  you can set it to a lower value for the times when you should not be losing speed.
- No Wallbang
  Counts lateral contact with the car as a failure.
- No Slide
  Counts the car sliding as a failure,
  though it should be noted that this property seemingly counts any skidmarks as sliding already,
  even if none of the wheels are sliding.
- Min/Max Wheels Sliding
  The minimum/maximum amount of wheels that are allowed to be sliding.

The three speed constraints are really map-dependent,
and the no wallbang seems like a good idea most of the time (unless you actually need a wallbang of course).
For noslides, it is ironically enough a bad idea to use the 'No Slide' option, because it leads to too shallow steering.
The max wheels sliding is preferred for the purpose of nosliding.
The min wheels sliding is apparently needed for island SD's (I do not even have TMUF).

As always, a good setup is important to get the desired position/angle during and after the evaluated timerange.
Especially for wallhugs it can take some trail and error to get this right.

Some symptoms of improvable wallhug entries:
- Shallow steering, followed by large and sudden steering changes could be the result of starting too close to the wall.
- If the steering starts at a high value,
  and then quickly (though still somewhat smoothly) goes down to start following the wall, consider an earlier beginning time.
- If the steering starts at a low value,
  and then quickly (though still somewhat smoothly) goes up to start following the wall, consider a later beginning time.
It can also help to try a few different entries without evaluating a timerange that covers the whole wall,
to not waste time on entries that do not work well, e.g. at first only seeing how the first 1s-2s go.

### Run-Mode

Run-Mode Evaluation is an feature that allows you to run Incremental in a race (i.e. `ContextMode::Run`),
rather than the usual validation context (i.e. `ContextMode::Simulation`).

When you want to use this, you will need to have an input file loaded.
The 'replay time' setting will then be used to determine up to what time the file will be played,
and the input events at that point will be used in the evaluation.
Much like in Simulation Mode, this time can also be used as an alternative to manually setting the evaluation's end time.

After the (run-mode) evaluation finishes, the original input file will be re-opened
(it needed to be closed to not interfere with the evaluation).
The 'Open Result File' setting will instead make it so Incremental tries to load the result file,
and only re-open the original input file if that fails for whatever reason.

The reason the activation is done with a checkbox rather than a button is just so you can undo it
if clicked by accident outside of an active race.

### Misc

The 'print extra info' setting makes it so extra information about the simulation is printed alongside the usual information.
As of writing, this is just the speed of the car in km/h.

The 'terminal title info level' setting makes it so the title bar of the terminal displays certain information:
1. "Incremental".
2. The previous level, as well as the current iteration compared to the total amount of iterations.
3. The previous level, as well as the lower/current/upper times in ms.
According to the TMInterface API documentation, the terminal title should not be changed too often,
which implies there could be noticable performance overhead, though in most cases it should not matter that much.

## Patch Notes

### v3.3.0

- Improved performance in cases where there are a lot of inputs after the given beginning time
  (e.g. running input simplifier on a replay with a lot of inputs).
- Renamed Run-Mode Bruteforce to Run-Mode Evaluation.
- Did some small fixes and performance improvements.

### v3.2.1

- SteerMax: Replaced steer offset refining checkbox with a combo of steer offset 'strategies',
  including a shorthand for 0 offset,
  which could be useful for noslide without it forgetting your manual steer offset var's value for e.g. wallhugs.
- Did some small fixes.
- Changed some var names and the corresponding UI.

### v3.2.0

- Added dynamic and absolute lookahead strategies to SteerMax.
- Added steer offset refining to SteerMax.
- Fixed a bug relating to preserving inputs between the base time and the time at which an iteration starts.

### v3.1.2

- Added a setting to ignore the speed bleed constraint while gearing.
- Removed the condition for speed constraints to be checked only if speed decreased (thus allowing negative values to work).
- Changed all time vars to be >= 0ms, rather than some time vars being >= 20ms.

### v3.1.1

- Added min/max sliding wheels constraint to SteerMax ('No Sliding' default value is now false).
- Added 'Single Iteration' option to set both ends of the iteration timerange more easily (with UI improvements).

### v3.1.0

- Added mode: SteerMax.
- Removed mode: Wallhugger.
- Rewrote large parts of the core logic (especially w.r.t. run-mode bruteforce).
- Fixed a bug in SD Railgun where a steering value would be skipped.
- Fixed bugs in Input Simplifier relating to inputs not being filled correctly (especially with brake minimization).
- Changed default context timespan of Input Simplifier from 250ms to 400ms.
- Many other small changes/fixes...

### v3.0.1

- Fixed SD quality threshold bug.

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
