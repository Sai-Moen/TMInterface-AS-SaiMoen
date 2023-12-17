// Shares utils that can be used in other modules

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = "smn_utils";
    info.Description = "SaiMoen's Utilities Library";
    info.Version = "v2.0.1.0";
    return info;
}

// The following functions need to be in global scope since they add overloads to global API.

// log primitive
shared void log(const bool b, Severity severity = Severity::Info)    { log(smnu::str::ingify(b), severity); }
shared void log(const uint u, Severity severity = Severity::Info)    { log(smnu::str::ingify(u), severity); }
shared void log(const uint64 ub, Severity severity = Severity::Info) { log(smnu::str::ingify(ub), severity); }
shared void log(const int i, Severity severity = Severity::Info)     { log(smnu::str::ingify(i), severity); }
shared void log(const int64 ib, Severity severity = Severity::Info)  { log(smnu::str::ingify(ib), severity); }
shared void log(const float f, Severity severity = Severity::Info)   { log(smnu::str::ingify(f), severity); }
shared void log(const double d, Severity severity = Severity::Info)  { log(smnu::str::ingify(d), severity); }

// log
shared void log(const dictionaryValue dv, Severity severity = Severity::Info) { log(smnu::str::ingify(dv), severity); }
shared void log(const smnu::HandleStr@ const hs, Severity severity = Severity::Info)
{
    log(smnu::str::ingify(hs), severity);
}

// print primitive
shared void print(const bool b, Severity severity = Severity::Info)    { print(smnu::str::ingify(b), severity); }
shared void print(const uint u, Severity severity = Severity::Info)    { print(smnu::str::ingify(u), severity); }
shared void print(const uint64 ub, Severity severity = Severity::Info) { print(smnu::str::ingify(ub), severity); }
shared void print(const int i, Severity severity = Severity::Info)     { print(smnu::str::ingify(i), severity); }
shared void print(const int64 ib, Severity severity = Severity::Info)  { print(smnu::str::ingify(ib), severity); }
shared void print(const float f, Severity severity = Severity::Info)   { print(smnu::str::ingify(f), severity); }
shared void print(const double d, Severity severity = Severity::Info)  { print(smnu::str::ingify(d), severity); }

// print
shared void print(const dictionaryValue dv, Severity severity = Severity::Info) { print(smnu::str::ingify(dv), severity); }
shared void print(const smnu::HandleStr@ const hs, Severity severity = Severity::Info)
{
    print(smnu::str::ingify(hs), severity);
}
