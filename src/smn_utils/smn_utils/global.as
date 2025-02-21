// smn_utils - v2.1.1a

/*

Global namespace
- extra log/print overloads
- var wrappers

*/


void log() { log(""); }

void log(const bool value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint64 value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int value,    Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int64 value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const float value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const double value, Severity severity = Severity::Info) { log("" + value, severity); }


void print() { print(""); }

void print(const bool value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint64 value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int value,    Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int64 value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const float value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const double value, Severity severity = Severity::Info) { print("" + value, severity); }


ms GetVariableTime(const string &in name)
{
    return ms(GetVariableDouble(name));
}

int GetVariableInt(const string &in name)
{
    return int(GetVariableDouble(name));
}

vec3 GetVariableVec3(const string &in name)
{
    return Text::ParseVec3(GetVariableString(name));
}


void SetVariableVec3(const string &in name, const vec3 value)
{
    SetVariable(name, value.ToString());
}


void DrawGame(const bool value)
{
    SetVariable("draw_game", value);
}
