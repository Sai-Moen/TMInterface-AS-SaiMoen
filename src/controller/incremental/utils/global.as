// log
void log()                                                    { log(""); }
void log(const bool b, Severity severity = Severity::Info)    { log("" + b, severity); }
void log(const uint u, Severity severity = Severity::Info)    { log("" + u, severity); }
void log(const int i, Severity severity = Severity::Info)     { log("" + i, severity); }
void log(const uint64 ub, Severity severity = Severity::Info) { log("" + ub, severity); }
void log(const int64 ib, Severity severity = Severity::Info)  { log("" + ib, severity); }
void log(const float f, Severity severity = Severity::Info)   { log("" + f, severity); }
void log(const double d, Severity severity = Severity::Info)  { log("" + d, severity); }

// print
void print()                                                    { print(""); }
void print(const bool b, Severity severity = Severity::Info)    { print("" + b, severity); }
void print(const uint u, Severity severity = Severity::Info)    { print("" + u, severity); }
void print(const int i, Severity severity = Severity::Info)     { print("" + i, severity); }
void print(const uint64 ub, Severity severity = Severity::Info) { print("" + ub, severity); }
void print(const int64 ib, Severity severity = Severity::Info)  { print("" + ib, severity); }
void print(const float f, Severity severity = Severity::Info)   { print("" + f, severity); }
void print(const double d, Severity severity = Severity::Info)  { print("" + d, severity); }
