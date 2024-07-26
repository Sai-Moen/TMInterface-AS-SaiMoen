{{ site.header }}

# Speed Ladder

A Speed Bruteforce mode that moves the Evaluation Timeframe after a certain amount of iterations.

## Installation

- [v2.1.0a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/speed_ladder_v2.1.0a/speed_ladder.zip)

## Guide

The evaluation (eval) timeframe consists of two settings, evalFrom and evalTo,
the starting and ending time of evaluation respectively.
This mode will try to maximize speed inside of the eval timeframe.

The iteration limit is how many iterations to run before moving the eval timeframe,
after which it will take the same amount of iterations (the limit) to move it again.
The way it moves the eval timeframe is to calculate the difference between evalFrom and the best known time,
and then add this offset to both evalFrom and evalTo.

For example, suppose we have the following best speed in an eval timeframe of 6850-6900:
600 km/h at 6880ms, then if the eval timeframe moves, it will become 6880-6930.
So, evalFrom becomes the best known time and evalTo stays ahead of it with the same time difference.

## Patch Notes

### v2.1.0a

- Released.
