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

## Module

If you have a .zip file, then it means the plugin is most likely a folder instead of a file (let's say `plugin`).
In order to install this plugin you will have to extract that folder in the Plugins folder,
such that you end up with `Plugins/plugin/`.

If the .zip just contains a single .as file, then it's a standalone plugin.
This is not common as of writing, but this may change in the future.

If the .zip just contains a single folder, then it can be directly copied into the Plugins folder.
If the .zip contains multiple folders/files, then those need to be extracted into a folder in the Plugins folder.
The Windows "Extract all..." context option (right click on it) should make this pretty easy.
