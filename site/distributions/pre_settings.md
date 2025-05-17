{{ site.header2 }}

# PreSettings

Also known as Preset Settings, this plugin allows you to manage preset scripts.
It also has a command (`include`) which loads a script without overriding the currently loaded script.

## Installation

- [v2.1.1b](https://github.com/Sai-Moen/TMInterface-AS-SaiMoen/releases/download/pre_settings_v2.1.1b/pre_settings.zip)

## Guide

You can find the settings for this plugin in a settings page.
To find it, open the TMInterface settings, and look below all the built-in settings pages.

To add a new preset, go to the Create New Preset tab, fill in a name, and press the Create Preset button.
If you accidentally remove a preset from the plugin's knowledge, but there is a still a script in `Scripts/presets`,
you can recover it with the other button.

After adding the preset, it will show up in the Presets tab.
If you click a preset it will be run, and become the active preset.

The active preset can be edited/removed in the Edit Active Preset tab.
You can also add ConVars (console variables) that are not yet listed in the preset,
which also supports a filter to only add ConVars that start with that string.
For example, setting a filter of `bf` and then pressing Add All Missing ConVars will add all vars that start with `bf`.
Pressing the Save/Load Changes will save the file and load the preset.

The plugin also registers the `include` command, which runs a script, but doesn't override the currently loaded script.
So, if you do `load a.txt` followed by `load b.txt` will mean `a.txt` is no longer loaded.
If you do `include b.txt` instead then `a.txt` will still be loaded.

## Patch Notes

### v2.1.1b

Released (and published here separately for the first time).
