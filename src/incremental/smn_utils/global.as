/*

smn_utils | Global namespace | v2.1.1a

Features:
- Extra log/print overloads
- Var wrappers

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


bool GetConVarBool(const string &in name)
{
    return GetVariableBool(name);
}

uint GetConVarUInt(const string &in name)
{
    return uint(GetVariableDouble(name));
}

int GetConVarInt(const string &in name)
{
    return int(GetVariableDouble(name));
}

ms GetConVarTime(const string &in name)
{
    return ms(GetVariableDouble(name));
}

float GetConVarFloat(const string &in name)
{
    return GetVariableDouble(name);
}

double GetConVarDouble(const string &in name)
{
    return GetVariableDouble(name);
}

string GetConVarString(const string &in name)
{
    return GetVariableString(name);
}

vec3 GetConVarVec3(const string &in name)
{
    return Text::ParseVec3(GetVariableString(name));
}


void SetVariable(const string &in name, const vec3 value)
{
    SetVariable(name, value.ToString());
}


void DrawGame(const bool value)
{
    SetVariable("draw_game", value);
}
