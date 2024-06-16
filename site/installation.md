# Installing a plugin

This short guide is intended for the plugins from this website, but it should apply to most plugin installations.

## Plugins Folder

In any case you need to know where your TMInterface Plugins folder is.
It can be found in the `Documents/TMInterface/` folder, just like where your Scripts folder is.

The folder at `Documents/TMInterface/Plugins/` will now be referred to as the "Plugins folder".

## Standalone

If you have an .as file, let's say `plugin.as`,
then you can just place it directly into the Plugins folder,
such that you end up with `Plugins/plugin.as`.

If you have a .zip that just contains a single .as file, then it's a standalone plugin.
The file can be copied into the Plugins folder.
You should still end up with the file structure mentioned above.

## Module

If the .zip just contains a single folder, then it can be directly copied into the Plugins folder.
You should end up with something like `Plugins/plugin/` as a file structure.

## README

If you have a .zip, there might be a README file included with it.
This file is not required for the plugin to function,
but instead it might make it easier for you to function with the plugin.

Therefore, it doesn't need to end up in the Plugins folder,
but you might want to read it, as it is most likely a guide for the plugin.
