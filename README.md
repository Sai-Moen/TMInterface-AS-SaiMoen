# TMInterface-AS
Collection of TMInterface AngelScript scripts; modules and standalone scripts.

## How to install
In any case you need to know where your TMInterface Plugins folder is.
It can be found in TMInterface folder,
just like where your Scripts folder is.

### Standalone
To install a plugin inside of the standalone folder:
Simply copy the file over to your Plugins folder directly.
You should end up with an AS file in the Plugins folder.

Example:
If we wanted to install a standalone plugin named `plugin.as` into the Plugins folder,
we would would copy the file, or extract it from a source tree .zip if you downloaded the entire repository.
We should end up with the following file structure.

`TMInterface/Plugins/plugin.as`

### Module
To install a plugin inside of the module folder:
You should end up with all of the scripts from the module inside of a folder in Plugins.
If the module is distributed as a zip file,
you should extract all the files into a normal folder,
and then move that folder into the Plugins folder.
Extracting can be done with just Windows' builtin features,
by right-clicking the zip file and clicking 'Extract All...' to extract the files to a folder.

Example:
If we wanted to install a module named `mod` into the Plugins folder,
we would extract it from a .zip and then place it into the Plugins folder.
We should end up with the following file structure.

`TMInterface/Plugins/mod`

The `mod` folder should then contain .as files and could also contain more folders.

## How to use
The standalone scripts will be documented in the standalone folder.
The modules will be documented inside their own folder,
or not (in which case it's still a work in progress).
