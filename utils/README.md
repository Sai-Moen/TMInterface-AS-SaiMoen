# Utils

This directory contains some utilities that help with development.
They might be useful if anyone ever forks this, or maybe you can apply this idea to your own repo.

## zip_plugin

Takes a plugin somewhere relative to the project root and puts in a zip.
The zip is placed in a predefined directory relative to the project root.
If a README.md is found along with it, it will be placed in the root of the zip, instead of inside the plugin.

## link_plugin

Takes a plugin somewhere relative to the project root and symlinks it into the Plugins directory.
Assumes that your project is a subdirectory of `Documents/TMInterface`.

This solves the following problem:

The Plugins directory expects all modules and (especially) standalone plugins to not have any indirection.
The git repo can't be in the Plugins directory because TMInterface might not like the random crap that comes with it,
and also it's just a bad idea to litter in important directories.
Furthermore, git might try to track plugins that don't come from this repo,
and it'll just be a huge pain to .gitignore all of that.

The next option is to have them separated, and copy things back and forth while writing code and testing.
This is less messy, but doesn't make it less annoying.
