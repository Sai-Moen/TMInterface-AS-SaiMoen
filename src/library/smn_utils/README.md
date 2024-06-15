# SaiMoen's Utilities Library

Note (v2.1.0 and before): not currently usable as there is a bug with the `shared` feature in TMInterface.

## Installation

Simply extract the zip (if you haven't already),
and then place the module in the Plugins directory,
such that you end up with the following (relative) folder structure:

`TMInterface/Plugins/smn_utils`

After which you should remove everything else relating to the .zip extraction as any random folder that is not intended to be read as a plugin could cause errors (and it makes your Plugins folder messy).

## Guide

### Important
This library is not meant as something that does anything directly for the user.
If you are not a script developer and just needed to have this installed as a dependency,
you don't need to read any further.

### Using the library in a Plugin
Let's say we wanted to import a log and/or print function to print booleans.
You would do the following:

1. Find the shared function's signature in a source file.

```angelscript
// e.g. in main.as
// ...
shared void log(const bool b, Severity severity = Severity::Info)
// ...
shared void print(const bool b, Severity severity = Severity::Info)
// ...
```

2. Use the following syntax to import* them in your own module.

```angelscript
external shared log(const bool, Severity);
external shared print(const bool, Severity);
```

Notice how we don't need to specify parameter names, only types.
Although if you prefer to see a parameter name for whatever reason, there is no functional difference between having it or not.

*Keep in mind that an import statement does exist,
but as of writing it is not (yet?) implemented so even if we wanted to use it we couldn't.

3. Use them like any other function.

```angelscript
log(true); // logs true
```


Now let's say we want to import something from a namespace, this requires a bit of extra syntax.

```angelscript
namespace smnu
{
    external shared void Throw(const string &in);
}
```

As long as you keep in mind that you have to match the namespace when doing this, it should be fine.
The reason this was not necessary in the first example,
is because this library shares overloads of global API's globally as well,
but due to risk of name collisions most things are namespaced.

And yes, this way of nesting namespaces works as well, should you want to avoid extreme indenting:

```angelscript
namespace smnu::Dict
{
    external shared void ForEach(dictionary@ const, const Iter@ const);
}
```
