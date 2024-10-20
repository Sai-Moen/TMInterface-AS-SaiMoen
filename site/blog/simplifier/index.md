{{ site.header }}

# Explaining Input Simplification

By SaiMoen.

    They always talk about how the same inputs result in the same outcome,
    but never about how different inputs can result in the same outcome.
    - SaiMoen, 2024

In this article, I will explain input simplifiers,
and how they can create different inputs from a replay, that result in a run identical to the replay.

## How is this possible

For some quick context before I dive in,
the trackmania cars (at least in TMF) can steer anywhere in the range from -65536 to 65536,
so there are 131073 steering values in total (65536 to the left of 0, 0 itself, 65536 to the right of 0).
The exact numbers aren't so important, but if I reference them later you will not be confused now.

### Airtime

The most obvious example is what happens during airtime.
The only thing that matters during airtime is the direction in which you're steering,
which is either left, neutral (0), or right.

To a person new to the series, this might seem strange, because really it shouldn't matter.
After all, if the wheels are not on the ground, turning them should not have any effect, right?
However, countersteering (steering against angular speed to slow it down),
is what causes these directions to result in different simulation 'states'.
In theory, this means only the sign (-1, 0, or 1) matters, and not the magnitude ('distance' from 0).
In practice, it gets a bit more complicated, because there is surprisingly not only air in a car game.

### Ground Contact

Okay, so airtime was intuitively a case where the exact value does not matter that much,
but surely on the ground each steering value results in a unique run, right?
Not really, there is a concept called 'turning rate', which is the actual rate at which the car turns (as the name implies).
As it turns out, the steering value you input is more like a suggestion.

First, your inputs are fed into the game, which on each tick (update of the game that happens 100 times per second),
sets a value which I will refer to as 'input steer'.
This value is a number that goes from -1 to 1, so keyboard left is -1, and keyboard right is 1.
For analog inputs this divides the input by 65536, so that it also goes from -1 to 1.

On the next tick, the turning rate, which is also a number from -1 to 1, tries to become equal to the value of input steer.
If the value is within 0.2 in either direction, then it will be set to the value of input steer.
Otherwise, it will move by 0.2 towards input steer.

What all of this means, from the perspective of analog inputs,
is that your actual steering value only moves by 65536 * 0.2 = 13107.2 per tick.
In reality, analog steering values can only be integers, but you can think of it in this way.

As a consequence, the following two sets of inputs result in the same outcome (assuming no airtime):

    0 press up
    0.01 steer 65536
    0.11 steer 0

    0 press up
    0.01 steer 13108
    0.02 steer 26215
    0.03 steer 39322
    0.04 steer 52429
    0.05 steer 65536
    0.11 steer 52428
    0.12 steer 39321
    0.13 steer 26214
    0.14 steer 13107
    0.15 steer 0

The reason that the values are off by 1 sometimes is due to 13107.2 not being an integer,
so there might have to be some rounding away from the previous steering value, depending on the turning rate.

The second set of inputs is longer, but it also appears to be a bit smoother than the other one.
Matching the steering inputs with the turning rate like this is also referred to as 'input smoothing'.
Due to different strategies being added,
and also people not agreeing on the definition of 'smooth' (because 0 to fullsteer in 50ms is still fast),
the term 'simplifier' became more common.

### Removing Inputs

Another simplification technique is to remove inputs.
The best example of this is the first set of inputs from the previous section being way shorter than the smoother inputs.
When analog steering inputs remain the same over multiple consecutive ticks, only the first one is needed, i.e.:

    0.02 steer 6000
    0.06 steer 0

Is the same as:

    0.02 steer 6000
    0.03 steer 6000
    0.04 steer 6000
    0.05 steer 6000
    0.06 steer 0

Removing these consecutive equal inputs is also known as 'unfilling' the inputs.
This is the opposite of 'filling' the inputs, which is a bruteforce option that allows bruteforce to work with more inputs.

### Airbraking

Last but not least, airbraking is also something that can be simplified to be a 1-tick tap a lot of the time.

## How can this be used

For humans, this is more of a fun fact,
and as a game mechanic it mostly helps keyboard players get a bit more precision when tapping.

For TAS, this can be very important.
For example, from clips of TAS, you might have noticed how much jitter there is in the inputs.
As we've just established, this is not really necessary, so why is it in there?
The answer is mostly due to how bruteforce works.
Since it just randomizes inputs, it will completely trash the inputs over time, as long as it becomes locally optimized.
I won't go too deep into how that works, as I already have another article on bruteforce.

Now, if this was just an aesthetic problem, nobody would care.
However, there could very well be a cost to bruteforce having to deal with the mess it created.
If the inputs become that jittery,
there will be inputs that become so disconnected from the turning rate that changing them has no effect most of the time.
If this happens to all inputs, then of course bruteforce will get stuck, unless you get exponentially lucky over time.
That's not to say that bruteforce getting stuck means that this happened,
it could also just be that case the part being bruteforced is becoming really optimized.

## Plugins

Over the years, there were some scripts/plugins that attempted to automate the process of simplifying the inputs from a replay.
A problem that all of them had (including my first smoother),
was that there was no check for the generated inputs still being synchronized with the original replay.
If there was a bad assumption in the code about how to do smoothing then the result would just not be correct.

We already understood the turning rate part of it very early on,
but we never quite understood in which situations that strategy would not apply.
For example, if you tried to separate the turning rate and airtime strategies based on the amount of wheels on the ground,
it would always break somewhere else, regardless of the number.

Recently, I made another input simplifier,
that could detect a desync with the original replay and rollback its inputs if one occurred.
The problem with earlier simplifiers/smoothers is most likely the transitions between ground and air.
This is because while you're in the air, the turning rate is irrelevant,
so you can change the inputs as long as the sign of the value is the same.
Once you touch the ground, you must have the correct turning rate again, which simplifiers are not really prepared for.

The way my simplifier works right now, is that it will try all the strategies in a user-defined order,
and if a strategy fails, it will recover and go to the next strategy.
Since the simplifier can recover, you can at least be sure that it will produce the same run with different inputs,
even if it won't be simplified absolutely optimally.

Theoretically, a simplifier that does not recover can also work.
As long as you don't change inputs first, but look ahead far enough to detect what strategy you should use.
My simplifier already grabs some important values by simulating forwards and then loading a save state,
but deciding what strategy to use in advance seems difficult (and runs into the correctness issues mentioned before).

As of writing, the simplifier is part of the Incremental controller, which is a plugin that generates inputs sequentially.
Putting it in there ended up being a good choice, because input simplifying fits that model of input generation.
