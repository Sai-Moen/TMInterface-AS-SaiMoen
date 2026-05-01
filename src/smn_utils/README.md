# smn_utils

Compilation of useful code snippets for creating TMInterface AngelScript plugins.

## How to Use

Since neither of the code reuse features provided by angelscript (`shared`, `import`) are supported by the tmi implementation,
this library is designed to be vendored.
You can copy section of the smn_utils.as file, or the whole file, into your plugin (directory).
Though, for easier updating, it might help to keep it in a separate file.

## Discussion

There is also a strong argument against using `shared` at all:
It doesn't seem like it's possible for multiple versions of the same library to coexist,
so what if some plugins need a certain version and other plugins need another?

Unlike `shared`, `import` would be useful in certain cases where a plugin would like to expose an API,
e.g. a custom bruteforce controller like Incremental.
This library doesn't have an API, so that's why it's a vendor library instead.

Although API's could also be done by including a mode in the plugin's folder somewhere, that has the following problems:
- Users now need to mess around with the file structure, and edit the code if those modes also need to be called in Main.
- If the plugin's file structure ever changes, or the extraction of the ZIP goes wrong, it might mess up the modes.
- If plugins were to become loadable from a ZIP file, then that wouldn't work obviously.
