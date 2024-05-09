# SaiMoen's TMInterface Plugins

## Installing a plugin

### Plugins Folder

In any case you need to know where your TMInterface Plugins folder is.
It can be found in the `Documents/TMInterface/` folder, just like where your Scripts folder is.

The folder at `Documents/TMInterface/Plugins/` will now be referred to as the "Plugins" folder.

### Standalone

If you have an .as file, let's say `plugin.as`,
then you can just place it directly into the Plugins folder,
such that you end up with `Plugins/plugin.as`.

### Module

If you have a .zip file, then it means the plugin is most likely a folder instead of a file (let's say `plugin`).
In order to install this plugin you will have to extract that folder in the Plugins folder,
such that you end up with `Plugins/plugin/`.

If the .zip just contains a single .as file, then it's a standalone plugin.
This is not common as of writing, but this may change in the future.

If the .zip just contains a single folder, then it can be directly copied into the Plugins folder.
If the .zip contains multiple folders/files, then those need to be extracted into a folder in the Plugins folder.
The Windows "Extract all..." context option (right click on it) should make this pretty easy.

## Distributions

### Note on plugin versions

Before listing the links to each plugin's page,
I would also like to note that the versions of TMInterface listed are not always required.
It could also just be the version on which the plugin was developed,
so maybe a certain version of the plugin will work on an older version of TMInterface.
Similarly, an older plugin has a decent chance of still working on newer versions of TMInterface (depending on its API usage).

### Plugins

#### Active

- [Calculator](releases/calculator.md)
- [Finetune Location](releases/finetune_location.md)
- [Incremental](releases/incremental.md)
- [RammFinder](releases/rammfinder.md)

#### Archived

##### Active up to 2.1

- [RunEditor](releases/run_editor.md)

## Usage

A plugin might include a README file, or I will try to document the plugins on their respective release pages.
