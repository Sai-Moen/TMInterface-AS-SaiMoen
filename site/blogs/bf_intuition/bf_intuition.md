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
and then only keep improved versions of the run we started with (the *base* run), so that the result improves over time.
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

[TODO Continue]: /

## Summary

The most practical information:

[TODO Insert Summary List]: /

The following bonus sections add some more thoughts on various related subjects.

## Why not replace Bruteforce with AI

Not sure if anyone will even ask this, but I answered it anyway;

Currently, there are several TMNF AI agents in development that use TMInterface, however,
they are quite tricky to set up and take a lot of time to train.
This is not practical if you are trying to TAS, and you should really be doing the routing yourself,
and when optimizing smaller sections of a track (as a TASer),
bruteforce with a good base run will probably win against AI anyway.

Maybe in the future, when they are easier to set up and produce runs that can't be ignored,
we could see some kind of AI assistance for TASing emerge.

## Are All Bruteforce Controllers Random

A short definition for 'bruteforce controller' (also known as validation handler):
A mode that can be used instead of the built-in bruteforce mode, which can basically do anything in the simulation context.

So we know that the built-in bruteforce controller (i.e. 'bruteforce') pretty much requires randomness in order to function.
However, this doesn't need to be the case.

### Incremental

For example, the Incremental controller (made by yours truly), has modes like `sd_railgun` and `wallhugger`,
for which it wouldn't really make a lot of sense to introduce random numbers.
There is no need to pick random times to change inputs, the controller always goes from the start time to the end time.

This process happens one tick at a time (also referred to as iteration, to avoid confusion).
On each iteration, they run the same logic to find a certain steering value, so they will behave deterministically.
It would be possible to make an sd mode that picks a random steering value at some algorithmic step, but why would you?

### Input Smoothers

Another example would be input smoothers.
The purpose of an input smoother is to take a set of inputs,
and find a specific set of inputs that still produce the same output.
That new set of inputs is expected to be as smooth as possible, e.g. no unnecessary spikes.
Here it would actually be difficult to introduce random numbers, since you want the same run afterwards.

Interestingly, this kind of plugin can actually be useful for bruteforce.
If steering values are closer together, then basically any change will result in a different run,
meaning that no attempts go to waste on meaningless changes.

I will spare you the details on how that works, as it could be an entire blog post by itself.
