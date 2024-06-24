# Understanding Bruteforce Intuitively

By SaiMoen.
With the help of threadd.

It is assumed the reader is roughly familiar with how bruteforce works in TMInterface
([what-is-bf](https://donadigo.com/tminterface/what-is-bf)).
It's also mostly theoretical, as the practical part can only truly be learned by doing it yourself,
or learning from how others use bruteforce in practice.

This blog is aimed more at understanding how to actually reason about what it's doing,
and why, from first principles.

## Intro

Recently, I was reading some messages in the TMInterface Discord server, when I came across the following
[message(s)](https://discord.com/channels/847108820479770686/849394911849742366/1239311260604960859)
sent by threadd (see image below).
The context is essentially that someone couldn't get a noseboost, as bruteforce simply wasn't finding anything.
So, threadd explains that you can't just throw something into bruteforce and expect that it will try to solve your problems.

[Image of messages](initial_msg.png)

I agree with the general take, so now I will try to expand on it a little more.

## You Cannot Try Everything

So wait, why do we use this thing again?
Well, TMNF has a lot of possible states the car can be in.
The basic calculation shows that the car could branch out to (up to) 524292 different possible states from one tick to the next.

This is mostly because of the following:
there are 65536 steering values to the left, 0 steer exists, and then there are 65536 steering values to the right.
Ignoring (digital) gas and brake (the explanation for the extra factor of 4 in the earlier number),
this means that trying all possible permutations of steering values,
assuming an attempt rate of 1000/s over just 4 ticks (0.04s in-game), would take about 9.353 billion years.

Since that won't be happening, the next best thing is to try stuff randomly,
and then only keep improved versions of the run we started with (the **base** run), so that the result improves over time.
Which begs the question, what do we count as an improvement?

## Determining The Objective

The gut reaction of any TrackMania player would probably be to just count speed increase as an improvement.
This is actually a strategy that works in many situations, but it has some problems:
the bruteforcer can really just go anywhere and do anything to get improvements.

This highlights an intrinsic fact about bruteforce, which is that it doesn't care about your run at all.
And if a certain set of inputs results in, as threadd describes it,
a 'lower energy state' compared to another, then bruteforce is more likely to do that.
As long as it gets attempts that are 'improvements' to it, along the way.
To make it more likely to take a path you want, you must make your path the most likely one (if it isn't already).
In order to achieve that, you can use a bruteforce mode that applies more constraints, and/or use certain settings to do so.

For instance, triggers can help your car stay in a certain spot rather than going somewhere unintended.
Additionally, the `bf_condition_speed` variable can set a minimum speed,
that will automatically reject an attempt if it goes below that speed.

Another important aspect to this is the quality of the base run, see the following:
[Garbage In, Garbage Out](https://en.wikipedia.org/wiki/Garbage_in,_garbage_out)

I'm not trying to roast your runs, that is just what this phenomenon is called.
If bruteforce gets a bad base run (compared to what you want to happen),
then it has many opportunities to go down a trail of 'improvements' that are not really what you wanted.

## Search Space

An important term here is the [Search Space](https://en.wikipedia.org/wiki/Search_space).
The search space in this case is essentially all possible situations (states) that the car can find itself in.
What we would like to do is search through all of those, but we've already established that that would take too long.

So we have to move through this space in some way, and try to find a better state like that.
The base run is like a starting point, from which we can search.
Whenever bruteforce finds an improvement, we move to a new state in this space that we defined to be 'better',
then we search from there, and repeat.

Okay, so we can 'walk' somewhere, using improvements as our steps, but where do we end up?
Here are some possible cases:

- We walk so far that basically any attempt at another step fails.
  This can happen when the bruteforce result becomes very optimized.
  Just to reiterate, this doesn't mean *you* will find it maxed,
  just that according to your bruteforce setup it is *supposed* to be maxed.
- We walk until we get to a state where we are not quite maxed,
  but we can't progress because of something specific to the run that is eating all our attempts, like an obstacle.
  If we could just step back and try a different approach, we could get around it.
  However, since that would result in a (short-term) worse run according to our bruteforce setup, it can't do that.
  This is also known as a local optimum, which, as opposed to a global optimum, may not be the best solution.
  Since bruteforce is a local search, it does not necessarily try to find a global optimum.
- We have a plan to walk a difficult route (e.g. from nosepos to 1000 km/h noseboost),
  but our starting point is so far away that we can't take the first steps.
  Meaning that we should have started with a better nosepos so that our steps actually get us somewhere.

If anything, the first case is a special form of the second case,
where the local optimum is also the global optimum (or at least very close to it).
In any case, at some point bruteforce will get locked into a certain local optimum,
so you better set it up with a base run and settings so that it finds a good one.

## Relation To Settings

To preface, here is a short definition for 'bruteforce controller' (also known as validation handler):
A mode which can basically do anything in the simulation context, e.g. Bruteforce, Incremental, etc.

This part covers the Input Modification settings found in the built-in bruteforce controller.
I might also phrase things using the 'walking' anology from earlier.

### Input Modify Count

This setting loosely controls how large a step can be.
It can be useful for harder tricks since your base run doesn't really look like what you want.
In theory, it should be set proportionally to how much you expect the run to change.
In practice, people usually prefer a certain value or range of values for a certain kind of situation.

### Input Change Timeframe

These are the From/To times that determine when bruteforce gets to change inputs.

What happens every so often,
is that someone who is new to TMInterface will try to bruteforce the entirety of their manually driven run in finish time.
Then they will get confused that it not only runs very slowly,
but also it doesn't seem to change their inputs before a certain time.

The reason that happens is the [Butterfly Effect](https://en.wikipedia.org/wiki/Butterfly_effect).
Changing earlier inputs will have an increasingly significant effect on the rest of the run,
so it becomes very unlikely that bruteforce can actually get an improvement by doing that.

Instead, you should use the `finish` command to artificially finish a run so you can get a replay with inputs.
If you do this after a part that you want to bruteforce, you can then set the timeframe to include all relevant inputs.
In practice, that means that you won't see a timeframe of over 6 seconds that much.
Then again, I can't say that there is no situation in which you would want a larger timeframe.
The same goes for a minimum length, if you make the timeframe short enough then nothing will change,
but it all depends on what you're doing.

### Maximum Steering Difference

When a steering value is changed, it will use this to determine a random number to add.
The reason the maximum value for this setting is 131072 is because that is the jump from -65536 to 65536 (or vice versa).
There has been some confusion about certain values supposedly making your run invalid, which is false.
Bruteforce doesn't do extended steering, and in fact that feature has been removed as of TMInterface 2.1,
so any value is ensured to result in valid TAS runs.

Anyway, this setting will actually work fine for a wide range of values.
Much like [Input Modify Count](#input-modify-count), for harder tricks this is generally set higher.
For normal driving you could in theory even get away with a value as low as 13107.2, because of how turning rate works.
However you will often have less smooth inputs than that, so you'll want to have more than that in practice.

Commonly used values include powers of 2 like 16384, 32768, 65536, 131072.
The most used one is 65536 as far as I know.
And again, if the run doesn't need to radically change, just become more optimized, then you don't need as high of a value.

### Maximum Time Difference

This is a relatively 'coarse' setting, and if you convert keyboard steering to analog steering, even more so.
It can optimize up/down press/rel timings, which can help for something like noseboosts, to try out more different states.
Since it works based on time, just like the [Input Change Timeframe](#input-change-timeframe),
a slightly different value can have a considerable impact (hence it is a coarse setting).

To be entirely honest, I don't even know if I should make a recommendation for this setting,
whenever I used it, I kept it at 10ms and that worked when I had to do small steps.
I suppose with bigger steps come bigger time differences.

### Fill Inputs

If you want to target some very specific inputs within your timeframe, you might not want this.
Generally, this is a pretty useful setting to ensure that bruteforce has plenty of inputs to work with,
therefore I tend to have it enabled.

## Notes On Other Settings

### Read The Docs

Hopefully, whoever wrote the bruteforce mode or plugin has documented its settings.
If you want to get a deeper understanding of what they do,
and what values you should consider setting, then make sure to read it.

You might not completely understand the documentation, but hopefully it gives you a better idea on what to do.

### Eval Is Not Input Change

Something that I commonly see is that people will enter the same timeframe into the input change timeframe,
and whatever evaluation timeframe the selected bruteforce mode uses.
If these needed to be the same, whoever wrote that mode could've just grabbed the input change timeframe directly.
Obviously, it serves a different purpose than that.
In most modes, this timeframe is when it checks whether the current attempt counts as an improvement.
That means that making it super wide like the input change timeframe could have some unexpected results.

For example, if you bruteforce a sharp turn to keep as much speed as possible,
you will probably set the input change timeframe to match the start and end of the turn itself.
If you also set the evaluation timeframe to be that, then the mode could do just about anything,
like improving the speed before the turn, if your speed is highest at that point.
What we actually wanted was exit speed though,
so we should really restrict the evaluation timeframe to be more like 0.1-0.5 seconds at the end of the turn.
In fact, these timeframes don't even need to overlap, that's just how it usually goes.

For instance, the `sd_entry` plugin *does* require a longer evaluation timeframe.
More specifically, it should wrap (the start of) the SD.
Also it would be better to overlap it with the end of the input change timeframe,
since you still want to change some of the SD inputs themselves.

It all depends on what works best for the bruteforce mode and the run.

## Summary

The most practical information:

- Use the right tool for the job.
- Know how the tool works conceptually (don't need to know how the code works).
- Understand the settings, and try to imagine how certain values lead to certain states being searched.
- Supply it with a good base run that doesn't allow it to 'walk' the wrong way when it makes improvements.
- Experiment!

The following bonus sections add some more thoughts on various related subjects.

## Why Not Replace Bruteforce With AI

Currently, there are several TMNF AI agents in development that use TMInterface, however,
they are quite tricky to set up and take a lot of time to train.
This is not practical if you are trying to TAS, and you should really be doing the routing yourself,
and when optimizing smaller sections of a track (as a TASer),
bruteforce with a good base run will probably win against AI anyway.

Maybe in the future, when they are easier to set up and produce runs that can't be ignored,
we could see some kind of AI assistance for TASing emerge.

## Are All Bruteforce Controllers Random

So we know that the built-in bruteforce controller (i.e. 'bruteforce') pretty much requires randomness in order to function.
However, this doesn't need to be the case for all controllers.

### Incremental

For example, the Incremental controller (made by yours truly), has modes like `sd_railgun` and `wallhugger`,
for which it wouldn't really make a lot of sense to introduce random numbers.
There is no need to pick random times to change inputs, the controller always goes from the start time to the end time.

This process happens one tick at a time (also referred to as iteration, to avoid confusion).
On each iteration, they run the same logic to find a certain steering value, so they will behave deterministically.
So it would be possible to make an SD mode that picks a random steering value at some algorithmic step, but why would you?

As a side note, it could be argued that the incremental sub-modes are not 'bruteforce', strictly speaking.
They rely mostly on heuristics to avoid checking all steering values instead.
Though, there's not any problem with calling them bruteforce as an umbrella term.

### Input Smoothers

Another example would be input smoothers.
The purpose of an input smoother is to take a set of inputs,
and find a specific set of inputs that still produce the same output.
That new set of inputs is expected to be as smooth as possible, e.g. no unnecessary spikes.
Here it would actually be difficult to introduce random numbers, since you want the same run afterwards.

Interestingly, this kind of plugin can actually be useful for bruteforce.
If steering values are closer together, then basically any change will result in a different run,
meaning that no attempts go to waste on meaningless changes.

I will spare you the details on how that works (hint: turning rate), as it could be an entire blog post by itself.
