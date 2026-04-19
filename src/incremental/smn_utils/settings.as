/*

smn_utils | Settings | v3.0.0

Features:
- Var Get/Set Wrappers
- Settings

Notes:
Consider that the TMInterface documentation hints at the fact that variables are actually temporary,
and it is only continuously re-registering them that makes them (appear as) permanent 'settings'.
Whether this is actually true can be debated, because it does feel like vars stay around regardless, but oh well...

In general, the Settings class will crash on e.g. trying to Get an unregistered variable, instead of silently failing.
Apparently SetVariable also returns whether it succeeded, so the Settings class will crash on that failing too.

*/

bool   VarGetBool(  const string &in name) { return                 GetVariableBool(  name ); }
uint   VarGetUint(  const string &in name) { return uint(           GetVariableDouble(name)); }
uint64 VarGetUint64(const string &in name) { return uint64(         GetVariableDouble(name)); }
int    VarGetInt(   const string &in name) { return int(            GetVariableDouble(name)); }
int64  VarGetInt64( const string &in name) { return int64(          GetVariableDouble(name)); }
ms     VarGetMs(    const string &in name) { return ms(             GetVariableDouble(name)); }
float  VarGetFloat( const string &in name) { return float(          GetVariableDouble(name)); }
double VarGetDouble(const string &in name) { return                 GetVariableDouble(name ); }
vec2   VarGetVec2(  const string &in name) { return Text::ParseVec2(GetVariableString(name)); }
vec3   VarGetVec3(  const string &in name) { return Text::ParseVec3(GetVariableString(name)); }
string VarGetString(const string &in name) { return                 GetVariableString(name ); }

bool VarSetBool(  const string &in name, const bool       value) { return SetVariable(name, value);            }
bool VarSetUint(  const string &in name, const uint       value) { return SetVariable(name, double(value));    }
bool VarSetUint64(const string &in name, const uint64     value) { return SetVariable(name, double(value));    }
bool VarSetInt(   const string &in name, const int        value) { return SetVariable(name, double(value));    }
bool VarSetInt64( const string &in name, const int64      value) { return SetVariable(name, double(value));    }
bool VarSetMs(    const string &in name, const ms         value) { return SetVariable(name, double(value));    }
bool VarSetFloat( const string &in name, const float      value) { return SetVariable(name, double(value));    }
bool VarSetDouble(const string &in name, const double     value) { return SetVariable(name, value);            }
bool VarSetVec2(  const string &in name, const vec2       value) { return SetVariable(name, value.ToString()); }
bool VarSetVec3(  const string &in name, const vec3       value) { return SetVariable(name, value.ToString()); }
bool VarSetString(const string &in name, const string &in value) { return SetVariable(name, value);            }


enum SettingKind
{
    NONE, // Likely forgot to set.

    BOOL,
    UINT, UINT64,
    INT, INT64,
    MS,
    FLOAT, DOUBLE,
    VEC2, VEC3,
    STRING,

    COUNT // The amount of SettingKinds.
}

const array<string> SETTING_KIND_NAMES =
{
    ,

    "BOOL",
    "UINT", "UINT64",
    "INT", "INT64",
    "MS",
    "FLOAT", "DOUBLE",
    "VEC2", "VEC3",
    "STRING"
};

class Setting
{
    SettingKind kind;
    string name;
    dictionaryValue defaultValue;
}

class Settings
{
    string prefix;
    dictionary settings;

	Settings(const string &in prefix, const Settings@ parent = null)
	{
        string s;
        if (parent !is null)
            s += parent.prefix;
        s += prefix + "_";
		this.prefix = s;
	}


    // - Settings Create

    void Create(const string &in relativeName, const dictionaryValue &in defaultValue, const SettingKind kind)
    {
        if (settings.Exists(relativeName))
        {
            string s;
            s += "Tried to create existing variable '";
            s += relativeName;
            s += "'";
            PanicLog(s);
            return; // unreachable
        }

        Setting setting;
        setting.kind = kind;
        setting.name = prefix + relativeName;
        setting.defaultValue = defaultValue;
        settings[relativeName] = setting;
    }

    void CreateBool(const string &in relativeName, const bool defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::BOOL);
    }

    void CreateUint(const string &in relativeName, const uint defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::UINT);
    }

    void CreateUint64(const string &in relativeName, const uint64 defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::UINT64);
    }

    void CreateInt(const string &in relativeName, const int defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::INT);
    }

    void CreateInt64(const string &in relativeName, const int64 defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::INT64);
    }

    void CreateMs(const string &in relativeName, const ms defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::MS);
    }

    void CreateFloat(const string &in relativeName, const float defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::FLOAT);
    }

    void CreateDouble(const string &in relativeName, const double defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::DOUBLE);
    }

    void CreateVec2(const string &in relativeName, const vec2 defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::VEC2);
    }

    void CreateVec3(const string &in relativeName, const vec3 defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::VEC3);
    }

    void CreateString(const string &in relativeName, const string &in defaultValue)
    {
        const dictionaryValue dv = defaultValue;
        Create(relativeName, dv, SettingKind::STRING);
    }

    void Load()
    {
        const auto@ const keys = settings.GetKeys();
        const uint length = keys.Length;
        for (uint i = 0; i < length; ++i)
        {
            Setting@ setting = Get(keys[i]);
            switch (setting.kind)
            {
            case SettingKind::BOOL:
                RegisterVariable(setting.name, bool(setting.defaultValue));
            break;
            case SettingKind::UINT:
            case SettingKind::UINT64:
            case SettingKind::INT:
            case SettingKind::INT64:
            case SettingKind::MS:
            case SettingKind::FLOAT:
            case SettingKind::DOUBLE:
                RegisterVariable(setting.name, double(setting.defaultValue));
            break;
            case SettingKind::VEC2:
            case SettingKind::VEC3:
            case SettingKind::STRING:
                RegisterVariable(setting.name, string(setting.defaultValue));
            break;
            default:
                PanicLog("Undefined SettingKind in Load");
            break;
            }
        }
    }


    // - Settings Get

    Setting@ Get(const string &in relativeName) const
    {
        Setting@ setting;
        if (settings.Get(relativeName, setting))
            return setting;

        string s;
        s += "Could not get variable from Settings with relativeName: '";
        s += relativeName;
        s += "'";
        PanicLog(s);
        return null; // unreachable
    }

    Setting@ GetOfKind(const string &in relativeName, const SettingKind expected) const
    {
        Setting@ setting = Get(relativeName);
        SettingKind actual = setting.kind;
        if (expected == actual)
            return setting;

        string s;
        s += "Could not get '";
        s += setting.name;
        s += "'.\n";
        s += "Expected: 'SettingKind::";
        s += SETTING_KIND_NAMES[expected];
        s += "', Actual: 'SettingKind::";
        s += SETTING_KIND_NAMES[actual];
        s += "'";
        PanicLog(s);
        return null; // unreachable
    }

    bool   GetBool(  const string &in relativeName) const { return VarGetBool(  GetOfKind(relativeName, SettingKind::BOOL  ).name); }
    uint   GetUint(  const string &in relativeName) const { return VarGetUint(  GetOfKind(relativeName, SettingKind::UINT  ).name); }
    uint64 GetUint64(const string &in relativeName) const { return VarGetUint64(GetOfKind(relativeName, SettingKind::UINT64).name); }
    int    GetInt(   const string &in relativeName) const { return VarGetInt(   GetOfKind(relativeName, SettingKind::INT   ).name); }
    int64  GetInt64( const string &in relativeName) const { return VarGetInt64( GetOfKind(relativeName, SettingKind::INT64 ).name); }
    ms     GetMs(    const string &in relativeName) const { return VarGetMs(    GetOfKind(relativeName, SettingKind::MS    ).name); }
    float  GetFloat( const string &in relativeName) const { return VarGetFloat( GetOfKind(relativeName, SettingKind::FLOAT ).name); }
    double GetDouble(const string &in relativeName) const { return VarGetDouble(GetOfKind(relativeName, SettingKind::DOUBLE).name); }
    vec2   GetVec2(  const string &in relativeName) const { return VarGetVec2(  GetOfKind(relativeName, SettingKind::VEC2  ).name); }
    vec3   GetVec3(  const string &in relativeName) const { return VarGetVec3(  GetOfKind(relativeName, SettingKind::VEC3  ).name); }
    string GetString(const string &in relativeName) const { return VarGetString(GetOfKind(relativeName, SettingKind::STRING).name); }


    // - Settings Set

    void SettingPanic(const Setting@ setting)
    {
        string s;
        s += "Could not set '";
        s += setting.name;
        s += "'.";
        PanicLog(s);
    }

    void SetBool(const string &in relativeName, const bool value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::BOOL);
        if (!VarSetBool(setting.name, value))
            SettingPanic(setting);
    }

    void SetUint(const string &in relativeName, const uint value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::UINT);
        if (!VarSetUint(setting.name, value))
            SettingPanic(setting);
    }

    void SetUint64(const string &in relativeName, const uint64 value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::UINT64);
        if (!VarSetUint64(setting.name, value))
            SettingPanic(setting);
    }

    void SetInt(const string &in relativeName, const int value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::INT);
        if (!VarSetInt(setting.name, value))
            SettingPanic(setting);
    }

    void SetInt64(const string &in relativeName, const int64 value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::INT64);
        if (!VarSetInt64(setting.name, value))
            SettingPanic(setting);
    }

    void SetMs(const string &in relativeName, const ms value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::MS);
        if (!VarSetMs(setting.name, value))
            SettingPanic(setting);
    }

    void SetFloat(const string &in relativeName, const float value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::FLOAT);
        if (!VarSetFloat(setting.name, value))
            SettingPanic(setting);
    }

    void SetDouble(const string &in relativeName, const double value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::DOUBLE);
        if (!VarSetDouble(setting.name, value))
            SettingPanic(setting);
    }

    void SetVec2(const string &in relativeName, const vec2 value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::VEC2);
        if (!VarSetVec2(setting.name, value))
            SettingPanic(setting);
    }

    void SetVec3(const string &in relativeName, const vec3 value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::VEC3);
        if (!VarSetVec3(setting.name, value))
            SettingPanic(setting);
    }

    void SetString(const string &in relativeName, const string &in value)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::STRING);
        if (!VarSetString(setting.name, value))
            SettingPanic(setting);
    }


    // - Settings UI Extensions

    bool Checkbox(const string &in label, const string &in relativeName)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::BOOL);
        return UI::CheckboxVar(label, setting.name);
    }

    bool DragFloat3(
        const string &in label, const string &in relativeName,
        float speed = 1.0f, float min = 0.0f, float max = 0.0f, const string &in format = "%.3f")
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::VEC3);
        return UI::DragFloat3Var(label, setting.name, speed, min, max, format);
    }

    float InputFloat(
        const string &in label, const string &in relativeName,
        float step = 1.0f)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::FLOAT);
        return UI::InputFloatVar(label, setting.name, step);
    }

    int InputInt(
        const string &in label, const string &in relativeName,
        int step = 1)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::INT);
        return UI::InputIntVar(label, setting.name, step);
    }

    string InputText(const string &in label, const string &in relativeName)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::STRING);
        return UI::InputTextVar(label, setting.name);
    }

    ms InputTime(
        const string &in label, const string &in relativeName,
        ms step = 100, ms defaultTime = 0)
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::MS);
        return UI::InputTimeVar(label, setting.name, step, defaultTime);
    }

    float SliderFloat(
        const string &in label, const string &in relativeName, float min, float max,
        const string &in format = "%.3f")
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::FLOAT);
        return UI::SliderFloatVar(label, setting.name, min, max, format);
    }

    int SliderInt(
        const string &in label, const string &in relativeName, int min, int max,
        const string &in format = "%d")
    {
        Setting@ setting = GetOfKind(relativeName, SettingKind::INT);
        return UI::SliderIntVar(label, setting.name, min, max, format);
    }
}
