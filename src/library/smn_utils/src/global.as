// smn_utils - v2.1.1a

/*

Global namespace
- extra log/print overloads
- 'vars that could also be part of the API maybe'-wrappers

*/


// - log
void log() { log(""); }

void log(const bool value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint64 value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int value,    Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int64 value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const float value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const double value, Severity severity = Severity::Info) { log("" + value, severity); }


// - print
void print() { print(""); }

void print(const bool value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint64 value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int value,    Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int64 value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const float value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const double value, Severity severity = Severity::Info) { print("" + value, severity); }


// - ConVars

void DrawGame(const bool value)
{
    SetVariable("draw_game", value);
}
