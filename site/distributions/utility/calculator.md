{{ site.header }}

# Calculator

A command-line calculator.

## Installation

- [v2.1.0a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/v2.1.0a_small/calculator.zip)
- [v2.0.1.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/pre_docs/calculator.as)

## Guide

Everything has to be passed in as a separate argument (so whitespace inbetween), e.g.:

`calc_expr 2 * ( 31 + 4 )` yields 70.

There are two commands:

### calc_expr

This one calculates like a normal calculator.
For calculating with time values, use `calc_time`.

### calc_time

This one parses numbers as timestamps, and logs a time back instead of just a number.
It's pretty much the same as `calc_expr`, except that numbers are parsed and logged as timestamps.

## Patch Notes

### v2.1.0a

- Refactorings.

### v2.0.1.0

- Updated to `v2.0.1`.
