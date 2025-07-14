const string ITEM_SEP = ",";
const string PAIR_SEP = ":";
const string KIND_SEP = ";";
const string VERSION_SEP = "|";

void LogIfWrongCount()
{
    if (groupNames.Length != GroupKind::COUNT)         log("groupNames has wrong Length!",     Severity::Error);
    if (scalarNames.Length != ScalarKind::COUNT)       log("scalarNames has wrong Length!",    Severity::Error);
    if (conditionNames.Length != ConditionKind::COUNT) log("conditionNames has wrong Length!", Severity::Error);
}


// - Groups

enum GroupKind
{
    NONE = -1,

    POSITION,
    ROTATION,

    SPEED_GLOBAL,
    SPEED_LOCAL,

    WHEEL_FRONT_LEFT,
    WHEEL_FRONT_RIGHT,
    WHEEL_BACK_RIGHT,
    WHEEL_BACK_LEFT,

    COUNT // amount of group kinds
}

const array<string> groupNames =
{
    "Position",
    "Rotation",

    "Global Speed",
    "Local Speed",

    "Front Left Wheel",
    "Front Right Wheel",
    "Back Right Wheel",
    "Back Left Wheel"
};

class Group
{
    bool active;
}

array<Group> groups(GroupKind::COUNT);

string SerializeGroups()
{
    array<string> kinds(GroupKind::COUNT);
    for (uint i = 0; i < GroupKind::COUNT; i++)
    {
        const GroupKind groupKind = GroupKind(i);
        kinds[i] = groupNames[groupKind] + PAIR_SEP + SerializeBool(groups[groupKind].active);
    }
    return Text::Join({ "v2.0.0", Text::Join(kinds, KIND_SEP) }, VERSION_SEP);
}

void DeserializeGroups(const string &in s)
{
    array<string>@ const versioned = s.Split(VERSION_SEP);
    {
        string error;
        if (versioned.Length != 2)
        {
            error = "No version field detected";
        }
        else
        {
            const string version = versioned[0];
            if (version.IsEmpty() || version[0] != 'v')
            {
                error = "No version detected";
            }
            else
            {
                if (version != "v2.0.0")
                    error = "Unsupported version detected: " + version;
            }
        }

        if (!error.IsEmpty())
        {
            log(error + ", generating groups...");
            SaveGroups();
            return;
        }
    }

    array<string>@ const kinds = versioned[1].Split(KIND_SEP);
    for (uint i = 0; i < kinds.Length; i++)
    {
        array<string>@ const kv = kinds[i].Split(PAIR_SEP);
        if (kv.Length != 2)
        {
            log("Failed to deserialize group! Index: " + i, Severity::Error);
            continue;
        }

        const string keyString = kv[0];
        const GroupKind kind = GroupKind(groupNames.Find(keyString));
        if (kind == GroupKind::NONE)
        {
            log("Could not find this group: " + keyString, Severity::Warning);
            continue;
        }

        const string valueString = kv[1];
        bool value;
        if (!DeserializeBool(valueString, value))
        {
            log("Could not deserialize this group's value! String: " + valueString, Severity::Error);
            continue;
        }

        groups[kind].active = value;
    }
}


// - Scalars

enum ScalarKind
{
    NONE = -1,

    POSITION_X, POSITION_Y, POSITION_Z,
    ROTATION_YAW, ROTATION_PITCH, ROTATION_ROLL,

    SPEED_GLOBAL_X, SPEED_GLOBAL_Y, SPEED_GLOBAL_Z,
    SPEED_LOCAL_X, SPEED_LOCAL_Y, SPEED_LOCAL_Z,

    WHEEL_FL_X, WHEEL_FL_Y, WHEEL_FL_Z,
    WHEEL_FR_X, WHEEL_FR_Y, WHEEL_FR_Z,
    WHEEL_BR_X, WHEEL_BR_Y, WHEEL_BR_Z,
    WHEEL_BL_X, WHEEL_BL_Y, WHEEL_BL_Z,

    COUNT // amount of scalar kinds
}

const array<string> scalarNames =
{
    "X Position", "Y Position", "Z Position",
    "Yaw", "Pitch", "Roll",

    "Global X Speed", "Global Y Speed", "Global Z Speed",
    "Local X Speed (Sideways)", "Local Y Speed (Upwards)", "Local Z Speed (Forwards)",

    "X Front Left Wheel", "Y Front Left Wheel", "Z Front Left Wheel",
    "X Front Right Wheel", "Y Front Right Wheel", "Z Front Right Wheel",
    "X Back Right Wheel", "Y Back Right Wheel", "Z Back Right Wheel",
    "X Back Left Wheel", "Y Back Left Wheel", "Z Back Left Wheel"
};

class Scalar
{
    bool lower, upper;
    double valueLower, valueUpper;
    float displayLower, displayUpper;

    void Reset()
    {
        lower = false;
        upper = false;
        valueLower = 0;
        valueUpper = 0;
        displayLower = 0;
        displayUpper = 0;
    }
}

array<Scalar> scalars(ScalarKind::COUNT);

string SerializeScalars()
{
    array<string> kinds(ScalarKind::COUNT);
    for (uint i = 0; i < ScalarKind::COUNT; i++)
    {
        const ScalarKind scalarKind = ScalarKind(i);
        const Scalar@ const scalar = scalars[scalarKind];
        const array<string> kind =
        {
            SerializeBool(scalar.lower),
            SerializeBool(scalar.upper),
            scalar.valueLower,
            scalar.valueUpper,
            scalar.displayLower,
            scalar.displayUpper
        };
        kinds[i] = scalarNames[scalarKind] + PAIR_SEP + Text::Join(kind, ITEM_SEP);
    }
    return Text::Join({ "v2.0.0", Text::Join(kinds, KIND_SEP) }, VERSION_SEP);
}

void DeserializeScalars(const string &in s)
{
    array<string>@ const versioned = s.Split(VERSION_SEP);
    {
        string error;
        if (versioned.Length != 2)
        {
            error = "No version field detected";
        }
        else
        {
            const string version = versioned[0];
            if (version.IsEmpty() || version[0] != 'v')
            {
                error = "No version detected";
            }
            else
            {
                if (version != "v2.0.0")
                    error = "Unsupported version detected: " + version;
            }
        }

        if (!error.IsEmpty())
        {
            log(error + ", generating scalars...");
            SaveScalars();
            return;
        }
    }

    array<string>@ const kinds = versioned[1].Split(KIND_SEP);
    for (uint i = 0; i < kinds.Length; i++)
    {
        array<string>@ const kv = kinds[i].Split(PAIR_SEP);
        if (kv.Length != 2)
        {
            log("Failed to deserialize scalar! Index: " + i, Severity::Error);
            continue;
        }

        const string keyString = kv[0];
        const ScalarKind kind = ScalarKind(scalarNames.Find(keyString));
        if (kind == ScalarKind::NONE)
        {
            log("Could not find this scalar: " + keyString, Severity::Warning);
            continue;
        }

        const string valueString = kv[1];
        array<string>@ const values = valueString.Split(ITEM_SEP);
        if (values.Length != 6)
        {
            log("Could not deserialize this scalar's values! String: " + valueString, Severity::Error);
            continue;
        }

        bool lower;
        bool upper;
        if (!(DeserializeBool(values[0], lower) && DeserializeBool(values[1], upper)))
        {
            log("Could not deserialize this scalar's flags!", Severity::Error);
            continue;
        }

        const double valueLower = Text::ParseFloat(values[2]);
        const double valueUpper = Text::ParseFloat(values[3]);

        const double displayLower = Text::ParseFloat(values[4]);
        const double displayUpper = Text::ParseFloat(values[5]);

        Scalar@ const scalar = scalars[kind];
        scalar.lower = lower;
        scalar.upper = upper;
        scalar.valueLower = valueLower;
        scalar.valueUpper = valueUpper;
        scalar.displayLower = displayLower;
        scalar.displayUpper = displayUpper;
    }
}


// - Conditions

enum ConditionKind
{
    NONE = -1,

    MIN_REAL_SPEED,
    FREEWHEELING,
    SLIDING,
    WHEEL_TOUCHING,
    WHEEL_CONTACTS,

    CHECKPOINTS,

	RPM,
    GEAR,
    REAR_GEAR,

    GLITCHING,

    COUNT // amount of condition kinds
}

const array<string> conditionNames =
{
    "Minimum Real Speed",
    "Freewheeling",
    "Sliding",
    "Wheel Touching Wall",
    "Wheel Contacts",

    "Checkpoints",

	"RPM",
    "Gear",
    "Rear Gear",

    "Glitching"
};

class Condition
{
    bool active;
    double value, valueMin, valueMax;
    float display, displayMin, displayMax;

    bool MatchBool(const bool otherValue) const
    {
        return otherValue == (value != 0);
    }

    bool MatchUInt(const uint otherValue) const
    {
        return otherValue == uint(value);
    }

    bool CompareInt(const int otherValue) const
    {
        return otherValue >= int(valueMin) && otherValue <= int(valueMax);
    }

    bool CompareDouble(const double otherValue) const
    {
    	return otherValue >= valueMin && otherValue <= valueMax;
    }

    void Transfer()
    {
        value = display;
    }

    void TransferRange()
    {
        valueMin = displayMin;
        valueMax = displayMax;
    }

    void Reset()
    {
        value = 0;
        valueMin = 0;
        valueMax = 0;

        display = 0;
        displayMin = 0;
        displayMax = 0;
    }
}

array<Condition> conditions(ConditionKind::COUNT);

string SerializeConditions()
{
    array<string> kinds(ConditionKind::COUNT);
    for (uint i = 0; i < ConditionKind::COUNT; i++)
    {
        const ConditionKind conditionKind = ConditionKind(i);
        const Condition@ const condition = conditions[conditionKind];
        const array<string> kind =
        {
            SerializeBool(condition.active),

            condition.value,
            condition.valueMin,
            condition.valueMax,

            condition.display,
            condition.displayMin,
            condition.displayMax
        };
        kinds[i] = conditionNames[conditionKind] + PAIR_SEP + Text::Join(kind, ITEM_SEP);
    }
    return Text::Join({ "v2.0.0", Text::Join(kinds, KIND_SEP) }, VERSION_SEP);
}

void DeserializeConditions(const string &in s)
{
    array<string>@ const versioned = s.Split(VERSION_SEP);
    {
        string error;
        if (versioned.Length != 2)
        {
            error = "No version field detected";
        }
        else
        {
            const string version = versioned[0];
            if (version.IsEmpty() || version[0] != 'v')
            {
                error = "No version detected";
            }
            else
            {
                if (version != "v2.0.0")
                    error = "Unsupported version detected: " + version;
            }
        }

        if (!error.IsEmpty())
        {
            log(error + ", generating conditions...");
            SaveConditions();
            return;
        }
    }

    array<string>@ const kinds = versioned[1].Split(KIND_SEP);
    for (uint i = 0; i < kinds.Length; i++)
    {
        array<string>@ const kv = kinds[i].Split(PAIR_SEP);
        if (kv.Length != 2)
        {
            log("Failed to deserialize condition! Index: " + i, Severity::Error);
            continue;
        }

        const string keyString = kv[0];
        const ConditionKind kind = ConditionKind(conditionNames.Find(keyString));
        if (kind == ConditionKind::NONE)
        {
            log("Could not find this condition: " + keyString, Severity::Warning);
            continue;
        }

        const string valueString = kv[1];
        array<string>@ const values = valueString.Split(ITEM_SEP);
        if (values.Length != 7)
        {
            log("Could not deserialize this condition's values! String: " + valueString, Severity::Error);
            continue;
        }

        bool active;
        if (!DeserializeBool(values[0], active))
        {
            log("Could not deserialize this condition's active field! String: " + valueString, Severity::Error);
            continue;
        }

        const double value = Text::ParseFloat(values[1]);
        const double valueMin = Text::ParseFloat(values[2]);
        const double valueMax = Text::ParseFloat(values[3]);

        const float display = Text::ParseFloat(values[4]);
        const float displayMin = Text::ParseFloat(values[5]);
        const float displayMax = Text::ParseFloat(values[6]);

        Condition@ const condition = conditions[kind];
        condition.active = active;

        condition.value = value;
        condition.valueMin = valueMin;
        condition.valueMax = valueMax;

        condition.display = display;
        condition.displayMin = displayMin;
        condition.displayMax = displayMax;
    }
}


// - Misc

string SerializeBool(const bool b)
{
    return b ? "1" : "0";
}

bool DeserializeBool(const string &in s, bool &out b)
{
    bool ok;
    if (s == "0")
    {
        b = false;
        ok = true;
    }
    else if (s == "1")
    {
        b = true;
        ok = true;
    }
    else
    {
        b = false;
        ok = false;
    }
    return ok;
}

double ConvertDisplayToValue(const ScalarKind kind, const float display)
{
    return ConvertDisplayToValue(ScalarKindToGroupKind(kind), display);
}

double ConvertDisplayToValue(const GroupKind kind, const float display)
{
    double value;
    switch (kind)
    {
    case GroupKind::ROTATION:
        value = Math::ToRad(display);
        break;
    case GroupKind::SPEED_GLOBAL:
    case GroupKind::SPEED_LOCAL:
        value = display / 3.6;
        break;
    default:
        value = display;
        break;
    }
    return value;
}

vec3 ConvertDisplayToValue3(const ScalarKind kind, const vec3 &in display)
{
    return ConvertDisplayToValue3(ScalarKindToGroupKind(kind), display);
}

vec3 ConvertDisplayToValue3(const GroupKind kind, const vec3 &in display)
{
    vec3 value;
    value.x = ConvertDisplayToValue(kind, display.x);
    value.y = ConvertDisplayToValue(kind, display.y);
    value.z = ConvertDisplayToValue(kind, display.z);
    return value;
}

float ConvertValueToDisplay(const ScalarKind kind, const double value)
{
    return ConvertValueToDisplay(ScalarKindToGroupKind(kind), value);
}

float ConvertValueToDisplay(const GroupKind kind, const double value)
{
    float display;
    switch (kind)
    {
    case GroupKind::ROTATION:
        display = Math::ToDeg(value);
        break;
    case GroupKind::SPEED_GLOBAL:
    case GroupKind::SPEED_LOCAL:
        display = value * 3.6;
        break;
    default:
        display = value;
        break;
    }
    return display;
}

vec3 ConvertValueToDisplay3(const ScalarKind kind, const vec3 &in value)
{
    return ConvertValueToDisplay3(ScalarKindToGroupKind(kind), value);
}

vec3 ConvertValueToDisplay3(const GroupKind kind, const vec3 &in value)
{
    vec3 display;
    display.x = ConvertValueToDisplay(kind, value.x);
    display.y = ConvertValueToDisplay(kind, value.y);
    display.z = ConvertValueToDisplay(kind, value.z);
    return display;
}

string FormatVec3ByTargetGroup(const vec3 &in value, const uint precision = 12)
{
    string formatted;
    if (printByComponent)
    {
        const vec3 display = ConvertValueToDisplay3(targetGroup, value);
        formatted = FormatPrecise(display, precision);
    }
    else
    {
        formatted = FormatValueByGroup(targetGroup, value.Length(), precision);
    }
    return formatted;
}

string FormatValueByTarget(const double value, const uint precision = 12)
{
    const GroupKind groupKind = isTargetGrouped ? targetGroup : ScalarKindToGroupKind(targetScalar);
    return FormatValueByGroup(groupKind, value, precision);
}

string FormatValueByGroup(const GroupKind groupKind, const double value, const uint precision = 12)
{
    return FormatPrecise(ConvertValueToDisplay(groupKind, value), precision);
}

string FormatValueByScalar(const ScalarKind scalarKind, const double value, const uint precision = 12)
{
    return FormatPrecise(ConvertValueToDisplay(scalarKind, value), precision);
}

array<ScalarKind>@ GroupKindToScalarKinds(const GroupKind groupKind)
{
    array<ScalarKind> scalarKinds;
    switch (groupKind)
    {
    case POSITION:
        scalarKinds =
        {
            ScalarKind::POSITION_X,
            ScalarKind::POSITION_Y,
            ScalarKind::POSITION_Z
        };
        break;
    case ROTATION:
        scalarKinds =
        {
            ScalarKind::ROTATION_YAW,
            ScalarKind::ROTATION_PITCH,
            ScalarKind::ROTATION_ROLL
        };
        break;
    case SPEED_GLOBAL:
        scalarKinds =
        {
            ScalarKind::SPEED_GLOBAL_X,
            ScalarKind::SPEED_GLOBAL_Y,
            ScalarKind::SPEED_GLOBAL_Z
        };
        break;
    case SPEED_LOCAL:
        scalarKinds =
        {
            ScalarKind::SPEED_LOCAL_X,
            ScalarKind::SPEED_LOCAL_Y,
            ScalarKind::SPEED_LOCAL_Z
        };
        break;
    case WHEEL_FRONT_LEFT:
        scalarKinds =
        {
            ScalarKind::WHEEL_FL_X,
            ScalarKind::WHEEL_FL_Y,
            ScalarKind::WHEEL_FL_Z
        };
        break;
    case WHEEL_FRONT_RIGHT:
        scalarKinds =
        {
            ScalarKind::WHEEL_FR_X,
            ScalarKind::WHEEL_FR_Y,
            ScalarKind::WHEEL_FR_Z
        };
        break;
    case WHEEL_BACK_RIGHT:
        scalarKinds =
        {
            ScalarKind::WHEEL_BR_X,
            ScalarKind::WHEEL_BR_Y,
            ScalarKind::WHEEL_BR_Z
        };
        break;
    case WHEEL_BACK_LEFT:
        scalarKinds =
        {
            ScalarKind::WHEEL_BL_X,
            ScalarKind::WHEEL_BL_Y,
            ScalarKind::WHEEL_BL_Z
        };
        break;
    }
    return scalarKinds;
}

GroupKind ScalarKindToGroupKind(const ScalarKind scalarKind)
{
    GroupKind groupKind;
    switch (scalarKind)
    {
    case POSITION_X:
    case POSITION_Y:
    case POSITION_Z:
        groupKind = GroupKind::POSITION;
        break;
    case ROTATION_YAW:
    case ROTATION_PITCH:
    case ROTATION_ROLL:
        groupKind = GroupKind::ROTATION;
        break;
    case SPEED_GLOBAL_X:
    case SPEED_GLOBAL_Y:
    case SPEED_GLOBAL_Z:
        groupKind = GroupKind::SPEED_GLOBAL;
        break;
    case SPEED_LOCAL_X:
    case SPEED_LOCAL_Y:
    case SPEED_LOCAL_Z:
        groupKind = GroupKind::SPEED_LOCAL;
        break;
    case WHEEL_FL_X:
    case WHEEL_FL_Y:
    case WHEEL_FL_Z:
        groupKind = GroupKind::WHEEL_FRONT_LEFT;
        break;
    case WHEEL_FR_X:
    case WHEEL_FR_Y:
    case WHEEL_FR_Z:
        groupKind = GroupKind::WHEEL_FRONT_RIGHT;
        break;
    case WHEEL_BR_X:
    case WHEEL_BR_Y:
    case WHEEL_BR_Z:
        groupKind = GroupKind::WHEEL_BACK_RIGHT;
        break;
    case WHEEL_BL_X:
    case WHEEL_BL_Y:
    case WHEEL_BL_Z:
        groupKind = GroupKind::WHEEL_BACK_LEFT;
        break;
    default:
        groupKind = GroupKind::NONE;
        break;
    }
    return groupKind;
}
