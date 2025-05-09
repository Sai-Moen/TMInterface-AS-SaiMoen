const string ITEM_SEP = ",";
const string PAIR_SEP = ":";
const string KIND_SEP = "|";

void LogIfWrongCount()
{
    if (groupNames.Length != GroupKind::COUNT)         log("groupNames has wrong Length!",     Severity::Error);
    if (scalarNames.Length != ScalarKind::COUNT)       log("scalarNames has wrong Length!",      Severity::Error);
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
    array<string> kinds;
    for (uint i = 0; i < GroupKind::COUNT; i++)
    {
        const GroupKind groupKind = GroupKind(i);
        kinds.Add(groupNames[groupKind] + PAIR_SEP + SerializeBool(groups[groupKind].active));
    }
    return Text::Join(kinds, KIND_SEP);
}

void DeserializeGroups(const string &in s)
{
    array<string>@ const kinds = s.Split(KIND_SEP);
    if (kinds[0].IsEmpty())
    {
        log("Generating groups...", Severity::Success);
        SaveGroups();
        return;
    }

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
    bool lower;
    bool upper;
    double lowerValue;
    double upperValue;
    float lowerDisplay;
    float upperDisplay;

    void Reset()
    {
        lower = false;
        upper = false;
        lowerValue = 0;
        upperValue = 0;
        lowerDisplay = 0;
        upperDisplay = 0;
    }
}

array<Scalar> scalars(ScalarKind::COUNT);

string SerializeScalars()
{
    array<string> kinds;
    for (uint i = 0; i < ScalarKind::COUNT; i++)
    {
        const ScalarKind scalarKind = ScalarKind(i);
        const Scalar@ const scalar = scalars[scalarKind];
        const array<string> kind =
        {
            SerializeBool(scalar.lower),
            SerializeBool(scalar.upper),
            scalar.lowerValue,
            scalar.upperValue,
            scalar.lowerDisplay,
            scalar.upperDisplay
        };
        kinds.Add(scalarNames[scalarKind] + PAIR_SEP + Text::Join(kind, ITEM_SEP));
    }
    return Text::Join(kinds, KIND_SEP);
}

void DeserializeScalars(const string &in s)
{
    array<string>@ const kinds = s.Split(KIND_SEP);
    if (kinds[0].IsEmpty())
    {
        log("Generating scalars...", Severity::Success);
        SaveScalars();
        return;
    }

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

        const double lowerValue = Text::ParseFloat(values[2]);
        const double upperValue = Text::ParseFloat(values[3]);

        const double lowerDisplay = Text::ParseFloat(values[4]);
        const double upperDisplay = Text::ParseFloat(values[5]);

        Scalar@ const scalar = scalars[kind];
        scalar.lower = lower;
        scalar.upper = upper;
        scalar.lowerValue = lowerValue;
        scalar.upperValue = upperValue;
        scalar.lowerDisplay = lowerDisplay;
        scalar.upperDisplay = upperDisplay;
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

    "Gear",
    "Rear Gear",

    "Glitching"
};

class Condition
{
    bool active;
    double value;
    float display;

    void Reset()
    {
        //active = false; // unintuitive?
        value = 0;
        display = 0;
    }
}

array<Condition> conditions(ConditionKind::COUNT);

string SerializeConditions()
{
    array<string> kinds;
    for (uint i = 0; i < ConditionKind::COUNT; i++)
    {
        const ConditionKind conditionKind = ConditionKind(i);
        const Condition@ const condition = conditions[conditionKind];
        const array<string> kind =
        {
            SerializeBool(condition.active),
            condition.value,
            condition.display
        };
        kinds.Add(conditionNames[conditionKind] + PAIR_SEP + Text::Join(kind, ITEM_SEP));
    }
    return Text::Join(kinds, KIND_SEP);
}

void DeserializeConditions(const string &in s)
{
    array<string>@ const kinds = s.Split(KIND_SEP);
    if (kinds[0].IsEmpty())
    {
        log("Generating conditions...", Severity::Success);
        SaveConditions();
        return;
    }

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
        if (values.Length != 3)
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
        const float display = Text::ParseFloat(values[2]);

        Condition@ const condition = conditions[kind];
        condition.active = active;
        condition.value = value;
        condition.display = display;
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

double ConvertDisplayToValue(const GroupKind kind, const double display)
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

double ConvertValueToDisplay(const GroupKind kind, const double value)
{
    double display;
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

string FormatVec3ByTargetGroup(const vec3 &in value, const uint precision = 12)
{
    string formatted;
    if (printByComponent)
    {
        const vec3 display = vec3(
            ConvertValueToDisplay(targetGroup, value.x),
            ConvertValueToDisplay(targetGroup, value.y),
            ConvertValueToDisplay(targetGroup, value.z));

        formatted = FormatPrecise(display, precision);
    }
    else
    {
        formatted = FormatFloatByGroup(targetGroup, value.Length(), precision);
    }
    return formatted;
}

string FormatFloatByTargetScalar(const double value, const uint precision = 12)
{
    GroupKind groupKind;
    // discard
    ScalarKindToGroupKind(targetScalar, groupKind);
    return FormatFloatByGroup(groupKind, value, precision);
}

string FormatFloatByTarget(const double value, const uint precision = 12)
{
    string formatted;
    if (isTargetGrouped)
        formatted = FormatFloatByGroup(targetGroup, value, precision);
    else
        formatted = FormatFloatByTargetScalar(value, precision);
    return formatted;
}

string FormatFloatByGroup(const GroupKind groupKind, const double value, const uint precision = 12)
{
    const double display = ConvertValueToDisplay(groupKind, value);
    return FormatPrecise(display, precision);
}

bool GroupKindToScalarKinds(const GroupKind groupKind, array<ScalarKind> &out scalarKinds)
{
    bool ok = true;
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
    default:
        scalarKinds = {};
        ok = false;
        break;
    }
    return ok;
}

bool ScalarKindToGroupKind(const ScalarKind scalarKind, GroupKind &out groupKind)
{
    bool ok = true;
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
        ok = false;
        break;
    }
    return ok;
}