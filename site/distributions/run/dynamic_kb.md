{{ site.header }}

# Dynamic Keyboard

Features to help keyboard users (smoothing and action keys).

## Installation

- [v2.1.0a](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/v2.1.0a_small/dynamic_kb.zip)

## Guide

You can find the settings for this plugin in a settings page.
To find it, open the TMInterface settings, and look below all the built-in settings pages.

When the top-level enabled checkbox is ticked, all features can be enabled,
and your left/right inputs will automatically be converted to steer inputs (pad).

You will also be able to see that this plugin has limited powers in terms of removing keyboard inputs before they happen,
so usually you will see a keyboard input flash on the input display for at least 1 tick.

### Smoothing

To enable this feature, tick its checkbox.

#### Smoothing Size

This setting changes how many ticks are used to smooth your inputs.
There are diminishing returns, and a few thousand will have a noticable performance impact.

#### Smoothing Data Factor

This setting changes how much the older data is considered in the steering input calculation.

#### Smoothing Trend Factor

This setting changes how much it tries to find a trend.

### Action Keys

To enable this feature, tick its checkbox.
To add a new action key, type the key to bind to, and then add it using the button.
To change an action key's value, type a value in its text box, and press the rebind button.
To delete an action key, press its delete button.

The console will also show binds taking place.
