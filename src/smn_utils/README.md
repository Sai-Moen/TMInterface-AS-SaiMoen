# Smn Utils

Compilation of useful code snippets for creating TMInterface AngelScript plugins.

## How to Use

### Including code

The reason for putting the actual library code in the inner smn_utils folder ('the sub-folder'),
instead of the outer smn_utils folder, is so that it can easily be copied,
without the README, gitignore, and possibly other (local) files being unnecessarily added too.

Since neither of the code reuse features provided by angelscript (`shared`, `import`) are supported by the tmi implementation,
this library is designed to be vendored:
- You can copy sections of the code from the sub-folder into your plugin.
- You can copy files from the sub-folder into your plugin.
- You can copy the entire sub-folder into your plugin.

For the last two options, the plugin should be a folder.
For the first two options, there is a risk that you don't copy all the code that is required,
so that's why it's recommended to just copy the entire sub-folder.

It might be better for organizational purposes to keep the library code separate from main plugin code,
so that it's easier to see what library code in your plugin is potentially outdated (given that each file has a version).

Example folder structure: (sub-folder copied into the main plugin's folder)
```
/plugin_name/
    smn_utils/
        global.as
        ...
    x.as
    y.as
    z.as
    ...
```

### Namespacing

Since you have control over the code, if you want to namespace it,
you can just paste a file's contents into a namespace in your plugin.

The downside is that updating may take a bit more time, because you have to copy files one at a time.
The alternative would be for this library to namespace everything,
which inevitably leads to having to undo it in certain cases due to being annoying.
As well as C++-style namespaces not being suitable for libraries, since they don't actually solve the namespace collision issues
(e.g. what if you already have a namespace with the name that I choose,
then they kind of merge, and any update could cause collisions).

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
