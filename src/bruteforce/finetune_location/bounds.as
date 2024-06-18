// Bounds logic

const string BOUND_PREFIX = PREFIX + "bound_";

array<Group@> bounds =
{
    @Group(boundsPosition, "Position", PREFIX + "position_"),
    @Group(boundsRotation, "Rotation", PREFIX + "rotation_"),
    @Group(boundsSpeed, "Speed", PREFIX + "speed_")
};

const string BOUND_X = BOUND_PREFIX + "x";
const string BOUND_Y = BOUND_PREFIX + "y";
const string BOUND_Z = BOUND_PREFIX + "z";

const dictionary boundsPosition =
{
    { BOUND_X, @Bound(Kind::X) },
    { BOUND_Y, @Bound(Kind::Y) },
    { BOUND_Z, @Bound(Kind::Z) }
};

const string BOUND_YAW   = BOUND_PREFIX + "yaw";
const string BOUND_PITCH = BOUND_PREFIX + "pitch";
const string BOUND_ROLL  = BOUND_PREFIX + "roll";

const dictionary boundsRotation =
{
    { BOUND_YAW,   @Bound(Kind::YAW)   },
    { BOUND_PITCH, @Bound(Kind::PITCH) },
    { BOUND_ROLL,  @Bound(Kind::ROLL)  }
};

const string BOUND_SPEED = BOUND_PREFIX + "speed";

const dictionary boundsSpeed =
{
    { BOUND_SPEED, @Bound(Kind::SPEED) }
};

enum Kind
{
    NONE,
    X, Y, Z,
    YAW, PITCH, ROLL,
    SPEED,

    FL_X, FL_Y, FL_Z,
    FR_X, FR_Y, FR_Z,
    BR_X, BR_Y, BR_Z,
    BL_X, BL_Y, BL_Z,
}

array<string>@ const modes =
{
    "", "X", "Y", "Z", "Yaw", "Pitch", "Roll", "Speed"
};

class Bound
{
    protected const string& SEP { get const { return " "; } }

    Bound(const Kind k)
    {
        kind = k;
    }

    Kind kind;

    bool enableLower;
    double lower;

    bool enableUpper;
    double upper;

    bool InRange(SimulationManager@ simManager) const
    {
        double value;
        if (GetValue(simManager, kind, value)) return (!enableLower || lower < value) && (!enableUpper || value < upper);
        else return false;
    }

    string opConv() const
    {
        const string l = lower;
        const string u = upper;
        const array<string> a = { l, u };
        return Text::Join(a, SEP);
    }

    void FromString(const string &in s)
    {
        const auto@ const a = s.Split(SEP);
        if (a.Length != 2) return;

        lower = Text::ParseFloat(a[0]);
        upper = Text::ParseFloat(a[1]);
    }
}

bool GetValue(SimulationManager@ simManager, const Kind kind, double &out value)
{
    const auto@ const dyna = simManager.Dyna.RefStateCurrent;
    const iso4 location = dyna.Location;
    const vec3 position = location.Position;
    mat3 rotation = location.Rotation;

    switch (kind)
    {
    case Kind::X:
        value = position.x;
        break;
    case Kind::Y:
        value = position.y;
        break;
    case Kind::Z:
        value = position.z;
        break;
    case Kind::YAW:
        rotation.GetYawPitchRoll(value, void, void);
        break;
    case Kind::PITCH:
        rotation.GetYawPitchRoll(void, value, void);
        break;
    case Kind::ROLL:
        rotation.GetYawPitchRoll(void, void, value);
        break;
    case Kind::SPEED:
        value = dyna.LinearSpeed.Length() * 3.6;
        break;
    default:
        return Wheels::GetValue(simManager, kind, location, value);
    }

    return true;
}

class Group
{
    Group(const dictionary g, const string &in s, const string &in e)
    {
        group = g;
        name = s;
        ENABLED = e + "enabled";
    }

    dictionary group;

    string name;

    bool enabled;
    string ENABLED;

    void Register()
    {
        RegisterVariable(ENABLED, false);
        const auto@ const keys = GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            RegisterVariable(key, "");
            GetBound(key).FromString(GetVariableString(key));
        }
        enabled = GetVariableBool(ENABLED);
    }

    bool Validate(SimulationManager@ simManager)
    {
        if (!enabled) return true;

        const auto@ const keys = GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            if (!GetBound(key).InRange(simManager)) return false;
        }
        return true;
    }

    void Save()
    {
        SetVariable(ENABLED, enabled);
        const auto@ const keys = GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            SetVariable(key, string(GetBound(key)));
        }
    }

    Bound@ GetBound(const string &in key) const
    {
        return cast<Bound@>(group[key]);
    }

    array<string>@ GetKeys() const
    {
        return group.GetKeys();
    }
}
