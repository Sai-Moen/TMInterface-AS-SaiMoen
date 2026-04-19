/*

smn_utils | Global namespace | v3.0.0

Features:
- Extra log/print overloads
- Things that have to be set through vars for some reason

*/


void log() { log(""); }

void log(const bool value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint64 value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int value,    Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int64 value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const float value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const double value, Severity severity = Severity::Info) { log("" + value, severity); }

void log(const vec2 value, Severity severity = Severity::Info) { log(value.ToString(), severity); }
void log(const vec3 value, Severity severity = Severity::Info) { log(value.ToString(), severity); }


void print() { print(""); }

void print(const bool value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint64 value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int value,    Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int64 value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const float value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const double value, Severity severity = Severity::Info) { print("" + value, severity); }

void print(const vec2 value, Severity severity = Severity::Info) { print(value.ToString(), severity); }
void print(const vec3 value, Severity severity = Severity::Info) { print(value.ToString(), severity); }


void DrawGame(const bool value)
{
    SetVariable("draw_game", value);
}
