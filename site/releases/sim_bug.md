# Sim Bug

Bug Simulator (e.g. Ramm/Blue bugs).

## Installation

- [2.0.1.0](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/sim_bug_v2.0.1.0/sim_bug.as)

## Guide

Use `bug help` to get a list of all commands and what they do.

### Types of Bugs

Currently, the only type of bug is `rotations`, which rotates the car by adding angular velocity.
In the future, other types could be added.

### Example Command

`5.0 bug rotate 6 2 4`

This command schedules a rotation bug at 5000ms, with:
- A pitch movement of 6
- A yaw movement of 2
- A roll movement of 4

They can also go the other way by making the numbers negative: `5.0 bug rotate -6 -2 -4`
