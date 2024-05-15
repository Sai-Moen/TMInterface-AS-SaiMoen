# Understanding Bruteforce Intuitively

By SaiMoen.

It is assumed the reader is roughly familiar with how bruteforce works in TMInterface
([what-is-bf](https://donadigo.com/tminterface/what-is-bf)).
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

## The need for Bruteforce

So wait, why do we use this thing again?
Well, TMNF has a lot of possible states the car can be in.
The basic calculation shows that the car could branch out to (up to) 524292 different possible states from one tick to the next.

This is mostly because of the following:
there are 65536 steering values to the left, 0 steer exists, and then there are 65536 steering values to the right.
Ignoring gas and brake (the explanation for the extra factor of 4 in the earlier number),
this means that trying all possible combinations of steering values,
assuming a rate of 1000/s over just 4 ticks (0.04s in-game) would take about 9.353 billion years.

Since that won't be happening, the next best thing is to try stuff randomly,
and then only keep improved versions of the run we entered (the *base run*), so that the result improves over time.
Which begs the question, what do we count as an improvement?

## The goal of Bruteforce

The gut reaction of any TrackMania player would probably be to just count speed increase as an improvement.
This is actually a strategy that works in many situations, but it has some problems:
the bruteforcer can really just go anywhere and do anything to get improvements.

This highlights an intrinsic fact about bruteforce, which is that it doesn't care about your run at all.
And if a certain 'path' (not necessarily physical, I'll get to it later) is, as threadd describes it,
a 'lower energy state' compared to another, then bruteforce is more likely to take that path.
As long as it gets attempts that are 'improvements' to it, along the way.
To make it more likely to take a path you want, you must make your path the most likely one if it isn't.
In order to achieve that, you can use a bruteforce mode that applies more constraints, and/or use certain options to do so.

For instance, triggers can help your car stay in a certain spot rather than going somewhere unintended.
Additionally, the `bf_condition_speed` variable can set a minimum speed,
that will automatically reject an attempt if it goes below that speed.

Another important aspect to this is the quality of the base run, see the following:

### [Garbage In, Garbage Out](https://en.wikipedia.org/wiki/Garbage_in,_garbage_out)

I'm not trying to roast your runs, that is just what this phenomenon is called.

If bruteforce gets a significantly worse that optimal base run,
then it can take a lot more paths that can only be described as a mistake.

## The meaning of a path

This 'path' that I'm talking about does not need to refer solely to the movement of the car.
Think about the 'space' of all possible states the car can be in (position, angle, velocity, etc.) at some time.
The path could also be seen as a path across this space,
where bruteforce finds a state that could, for example, have a similar position but with a higher velocity.
