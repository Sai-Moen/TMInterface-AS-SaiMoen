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
    dictionaryValue value;
}

class Settings
{
    string prefix;
    dictionary settings;

	Settings(const string &in prefix, const Settings@ parent = null)
	{
        StringBuilder sb;
        if (parent !is null)
            sb.Append(parent.prefix);
        sb.Append(prefix).Append("_");
		this.prefix = sb.ToString();
	}


    // - Settings Create

    void Create(const string &in relativeName, const dictionaryValue &in defaultValue, const SettingKind kind)
    {
        Setting setting;
        setting.kind = kind;
        setting.name = prefix + relativeName;
        setting.value = defaultValue;
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
            Setting@ setting = Lookup(keys[i]);
            const SettingKind kind = setting.kind;
            const string name = setting.name;
            dictionaryValue value = setting.value;

            bool registered = true;
            switch (kind)
            {
            case SettingKind::BOOL:
                registered = RegisterVariable(name, bool(value));
            break;
            case SettingKind::UINT:
            case SettingKind::UINT64:
            case SettingKind::INT:
            case SettingKind::INT64:
            case SettingKind::MS:
            case SettingKind::FLOAT:
            case SettingKind::DOUBLE:
                registered = RegisterVariable(name, double(value));
            break;
            case SettingKind::VEC2:
            case SettingKind::VEC3:
            case SettingKind::STRING:
                registered = RegisterVariable(name, string(value));
            break;
            default:
                PanicLog("Undefined SettingKind in Load");
            break;
            }

            // A fresh variable, setting.value is already the default value as well, so no need to get it again.
            if (registered)
                continue;

            switch (kind)
            {
            case SettingKind::BOOL:   value = VarGetBool(name);   break;
            case SettingKind::UINT:   value = VarGetUint(name);   break;
            case SettingKind::UINT64: value = VarGetUint64(name); break;
            case SettingKind::INT:    value = VarGetInt(name);    break;
            case SettingKind::INT64:  value = VarGetInt64(name);  break;
            case SettingKind::MS:     value = VarGetMs(name);     break;
            case SettingKind::FLOAT:  value = VarGetFloat(name);  break;
            case SettingKind::DOUBLE: value = VarGetDouble(name); break;
            case SettingKind::VEC2:   value = VarGetVec2(name);   break;
            case SettingKind::VEC3:   value = VarGetVec3(name);   break;
            case SettingKind::STRING: value = VarGetString(name); break;
            default:
                PanicLog("Undefined SettingKind in Load");
            break;
            }

            setting.value = value;
        }
    }

    Setting@ Lookup(const string &in relativeName) const
    {
        Setting@ setting;
        if (settings.Get(relativeName, setting))
            return setting;

        StringBuilder sb; sb
            .Append("Could not get variable from Settings with relativeName: '")
            .Append(relativeName)
            .Append("'");
        PanicLog(sb.ToString());
        return null; // unreachable
    }


    // - Settings Get

    Setting@ Get(const string &in relativeName, const SettingKind expected) const
    {
        Setting@ setting = Lookup(relativeName);
        SettingKind actual = setting.kind;
        if (expected == actual)
            return setting;

        StringBuilder sb; sb
            .Append("Could not get '")
            .Append(setting.name)
            .AppendLine("'.")
            .Append("Expected: 'SettingKind::")
            .Append(SETTING_KIND_NAMES[expected])
            .Append("', Actual: 'SettingKind::")
            .Append(SETTING_KIND_NAMES[actual])
            .Append("'");
        PanicLog(sb.ToString());
        return null; // unreachable
    }

    bool   GetBool(  const string &in relativeName) const { return bool(  Get(relativeName, SettingKind::BOOL  ).value); }
    uint   GetUint(  const string &in relativeName) const { return uint(  Get(relativeName, SettingKind::UINT  ).value); }
    uint64 GetUint64(const string &in relativeName) const { return uint64(Get(relativeName, SettingKind::UINT64).value); }
    int    GetInt(   const string &in relativeName) const { return int(   Get(relativeName, SettingKind::INT   ).value); }
    int64  GetInt64( const string &in relativeName) const { return int64( Get(relativeName, SettingKind::INT64 ).value); }
    ms     GetMs(    const string &in relativeName) const { return ms(    Get(relativeName, SettingKind::MS    ).value); }
    float  GetFloat( const string &in relativeName) const { return float( Get(relativeName, SettingKind::FLOAT ).value); }
    double GetDouble(const string &in relativeName) const { return double(Get(relativeName, SettingKind::DOUBLE).value); }
    vec2   GetVec2(  const string &in relativeName) const { return vec2(  Get(relativeName, SettingKind::VEC2  ).value); }
    vec3   GetVec3(  const string &in relativeName) const { return vec3(  Get(relativeName, SettingKind::VEC3  ).value); }
    string GetString(const string &in relativeName) const { return string(Get(relativeName, SettingKind::STRING).value); }


    // - Settings Set

    void SettingPanic(const Setting@ setting)
    {
        StringBuilder sb; sb
            .Append("Could not set '")
            .Append(setting.name)
            .AppendLine("'.");
        PanicLog(sb.ToString());
    }

    void SetBool(const string &in relativeName, const bool value)
    {
        Setting@ setting = Get(relativeName, SettingKind::BOOL);
        if (!VarSetBool(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetUint(const string &in relativeName, const uint value)
    {
        Setting@ setting = Get(relativeName, SettingKind::UINT);
        if (!VarSetUint(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetUint64(const string &in relativeName, const uint64 value)
    {
        Setting@ setting = Get(relativeName, SettingKind::UINT64);
        if (!VarSetUint64(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetInt(const string &in relativeName, const int value)
    {
        Setting@ setting = Get(relativeName, SettingKind::INT);
        if (!VarSetInt(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetInt64(const string &in relativeName, const int64 value)
    {
        Setting@ setting = Get(relativeName, SettingKind::INT64);
        if (!VarSetInt64(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetMs(const string &in relativeName, const ms value)
    {
        Setting@ setting = Get(relativeName, SettingKind::MS);
        if (!VarSetMs(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetFloat(const string &in relativeName, const float value)
    {
        Setting@ setting = Get(relativeName, SettingKind::FLOAT);
        if (!VarSetFloat(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetDouble(const string &in relativeName, const double value)
    {
        Setting@ setting = Get(relativeName, SettingKind::DOUBLE);
        if (!VarSetDouble(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetVec2(const string &in relativeName, const vec2 value)
    {
        Setting@ setting = Get(relativeName, SettingKind::VEC2);
        if (!VarSetVec2(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetVec3(const string &in relativeName, const vec3 value)
    {
        Setting@ setting = Get(relativeName, SettingKind::VEC3);
        if (!VarSetVec3(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }

    void SetString(const string &in relativeName, const string &in value)
    {
        Setting@ setting = Get(relativeName, SettingKind::STRING);
        if (!VarSetString(setting.name, value))
            SettingPanic(setting);
        setting.value = value;
    }


    // - Settings UI Extensions

    bool Checkbox(const string &in label, const string &in relativeName)
    {
        Setting@ setting = Get(relativeName, SettingKind::BOOL);
        const bool value = UI::CheckboxVar(label, setting.name);
        setting.value = value;
        return value;
    }

    bool DragFloat3(
        const string &in label, const string &in relativeName,
        float speed = 1.0f, float min = 0.0f, float max = 0.0f, const string &in format = "%.3f")
    {
        Setting@ setting = Get(relativeName, SettingKind::VEC3);
        const string name = setting.name;
        const bool changed = UI::DragFloat3Var(label, name, speed, min, max, format);
        if (changed)
            setting.value = VarGetVec3(name);
        return changed;
    }

    float InputFloat(
        const string &in label, const string &in relativeName,
        float step = 1.0f)
    {
        Setting@ setting = Get(relativeName, SettingKind::FLOAT);
        const float value = UI::InputFloatVar(label, setting.name, step);
        setting.value = value;
        return value;
    }

    int InputInt(
        const string &in label, const string &in relativeName,
        int step = 1)
    {
        Setting@ setting = Get(relativeName, SettingKind::INT);
        const int value = UI::InputIntVar(label, setting.name, step);
        setting.value = value;
        return value;
    }

    string InputText(const string &in label, const string &in relativeName)
    {
        Setting@ setting = Get(relativeName, SettingKind::STRING);
        const string value = UI::InputTextVar(label, setting.name);
        setting.value = value;
        return value;
    }

    ms InputTime(
        const string &in label, const string &in relativeName,
        ms step = 100, ms defaultTime = 0)
    {
        Setting@ setting = Get(relativeName, SettingKind::MS);
        const ms value = UI::InputTimeVar(label, setting.name, step, defaultTime);
        setting.value = value;
        return value;
    }

    float SliderFloat(
        const string &in label, const string &in relativeName, float min, float max,
        const string &in format = "%.3f")
    {
        Setting@ setting = Get(relativeName, SettingKind::FLOAT);
        const float value = UI::SliderFloatVar(label, setting.name, min, max, format);
        setting.value = value;
        return value;
    }

    int SliderInt(
        const string &in label, const string &in relativeName, int min, int max,
        const string &in format = "%d")
    {
        Setting@ setting = Get(relativeName, SettingKind::INT);
        const int value = UI::SliderIntVar(label, setting.name, min, max, format);
        setting.value = value;
        return value;
    }
}
