{{ site.header }}

# Sim Bug

Bug Simulator (e.g. Ramm/Blue bugs).

## Installation

- [v2.1.0a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/v2.1.0a_small/sim_bug.zip)
- [v2.0.1.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/sim_bug_v2.0.1.0/sim_bug.as)

## Guide

Use `bug help` to get a list of all commands and what they do.

### Types of Bugs

There are two types:

- `bug rotate x y z`
- `bug speed x y z`

Both will add that vector to the car's local angular and linear speed respectively.
The bugs can also be scheduled by placing a time in front of them.

### Example Command

`5.0 bug rotate 6 2 4`

This command schedules a rotation bug at 5000ms, with:
- A pitch movement of 6
- A yaw movement of 2
- A roll movement of 4

They can also go the other way by making the numbers negative: `5.0 bug rotate -6 -2 -4`

## Patch Notes

### v2.1.0a

- Added speed bug type.

### v2.0.1.0

- Released.
