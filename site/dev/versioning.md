{{ site.header }}

# Versioning Scheme

## TMInterface 2.0 and 2.1

In these versions I copied the TMInterface version that the plugin was written on,
and added a letter to indicate the actual version.
Unsurprisingly, this didn't really convey very well how much the plugin changed between versions.

## TMInterface 2.2+

The plugin's major version maps to the TMInterface version like so:

    0 -> 1.5.x
    1 -> 2.0.x
    2 -> 2.1.x
    3 -> 2.2.x
    ...

(Of course the existing versions can't be changed retroactively, this is just the new logic.)

The minor version is used for significant changes, and the patch for patches.
Time will tell if I should just go full SemVer after all,
but it's not like this is some massive open-source project where someone else's code breaks because of what I do,
so it's not that important (but explaining it may be).
