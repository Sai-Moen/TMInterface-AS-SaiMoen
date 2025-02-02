# Smn Utils

Compilation of useful code snippets for creating TMInterface AngelScript plugins.

## How to Use

### Including code

Since neither of the code reuse features provided by angelscript (`shared`, `import`) are supported by the tmi implementation,
this library is designed to be vendored:
- You can copy sections of the code into your plugin.
- You can copy files into your plugin.
- You can copy the folder into your plugin.

For the last two options, the plugin should be a folder.
It might be better for organizational purposes to keep the library code separate from main plugin code,
so that it's easier to see what library code is outdated (given that each file has a version).

Example folder structure:
```
/plugin_name/
    smn_utils/
    main.as
    xyz.as
    ...
```

It's not possible to just put the library in the Plugins folder,
then TMInterface will complain that required functions are not implemented.

### Namespacing

Since you have control over the code, if you want to namespace it,
you can just paste a file's contents into a namespace in your plugin.

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
- If plugins will become loadable from a ZIP file, then that wouldn't work obviously.
