This directory contains some utilities that help with development.
They might be useful if anyone ever forks this, or maybe you can apply this idea to your own repo.

It solves the following problem:

The Plugins directory expects all modules and (especially) standalone plugins to not have any indirection.
The git repo can't be in the Plugins directory because TMInterface might not like the random crap that comes with it,
and also it's just a bad idea to litter in important directories.
Furthermore, git might try to track plugins that don't come from this repo,
and it'll just be a huge pain to .gitignore all of that.

The next option is to have them separated, and copy things back and forth while writing code and testing.
This is less messy, but doesn't make it less annoying.
And really, the files should just be the same inode (or whatever windows calls it).

So, I wrote some bats to automatically create a linked file/directory in the Plugins directory.
As well as bats to remove those links.
- `lnmod` Link Module
- `lnsta` Link Standalone
- `rmmod` Remove Module
- `rmsta` Remove Standalone
