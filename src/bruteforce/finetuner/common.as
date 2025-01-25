// - Groups
enum GroupKind
{
    NONE = -1,

    POSITION,
    ROTATION,

    SPEED_LOCAL,
    SPEED_GLOBAL,

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

    "Local Speed",
    "Global Speed",

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

// - Modes
enum ModeKind
{
    NONE = -1,

    POSITION_X, POSITION_Y, POSITION_Z,
    ROTATION_YAW, ROTATION_PITCH, ROTATION_ROLL,

    SPEED_LOCAL_X, SPEED_LOCAL_Y, SPEED_LOCAL_Z,
    SPEED_GLOBAL_X, SPEED_GLOBAL_Y, SPEED_GLOBAL_Z,

    WHEEL_FL_X, WHEEL_FL_Y, WHEEL_FL_Z,
    WHEEL_FR_X, WHEEL_FR_Y, WHEEL_FR_Z,
    WHEEL_BR_X, WHEEL_BR_Y, WHEEL_BR_Z,
    WHEEL_BL_X, WHEEL_BL_Y, WHEEL_BL_Z,

    COUNT // amount of mode kinds
}

const array<string> modeNames =
{
    "X Position", "Y Position", "Z Position",
    "Yaw", "Pitch", "Roll",

    "Local X Speed (Sideways)", "Local Y Speed (Upwards)", "Local Z Speed (Forwards)",
    "Global X Speed", "Global Y Speed", "Global Z Speed",

    "X Front Left Wheel", "Y Front Left Wheel", "Z Front Left Wheel",
    "X Front Right Wheel", "Y Front Right Wheel", "Z Front Right Wheel",
    "X Back Right Wheel", "Y Back Right Wheel", "Z Back Right Wheel",
    "X Back Left Wheel", "Y Back Left Wheel", "Z Back Left Wheel"
};

class Mode
{
    bool lower;
    bool upper;
    double lowerValue;
    double upperValue;

    bool IsActive()
    {
        return lower || upper;
    }
}

array<Mode> modes(ModeKind::COUNT);

bool GroupKindToModeKinds(const GroupKind groupKind, array<ModeKind> &out outModeKinds)
{
    bool found = true;
    switch (groupKind)
    {
    case POSITION:
        outModeKinds =
        {
            ModeKind::POSITION_X,
            ModeKind::POSITION_Y,
            ModeKind::POSITION_Z
        };
        break;
    case ROTATION:
        outModeKinds =
        {
            ModeKind::ROTATION_YAW,
            ModeKind::ROTATION_PITCH,
            ModeKind::ROTATION_ROLL
        };
        break;
    case SPEED_LOCAL:
        outModeKinds =
        {
            ModeKind::SPEED_LOCAL_X,
            ModeKind::SPEED_LOCAL_Y,
            ModeKind::SPEED_LOCAL_Z
        };
        break;
    case SPEED_GLOBAL:
        outModeKinds =
        {
            ModeKind::SPEED_GLOBAL_X,
            ModeKind::SPEED_GLOBAL_Y,
            ModeKind::SPEED_GLOBAL_Z
        };
        break;
    case WHEEL_FRONT_LEFT:
        outModeKinds =
        {
            ModeKind::WHEEL_FL_X,
            ModeKind::WHEEL_FL_Y,
            ModeKind::WHEEL_FL_Z
        };
        break;
    case WHEEL_FRONT_RIGHT:
        outModeKinds =
        {
            ModeKind::WHEEL_FR_X,
            ModeKind::WHEEL_FR_Y,
            ModeKind::WHEEL_FR_Z
        };
        break;
    case WHEEL_BACK_RIGHT:
        outModeKinds =
        {
            ModeKind::WHEEL_BR_X,
            ModeKind::WHEEL_BR_Y,
            ModeKind::WHEEL_BR_Z
        };
        break;
    case WHEEL_BACK_LEFT:
        outModeKinds =
        {
            ModeKind::WHEEL_BL_X,
            ModeKind::WHEEL_BL_Y,
            ModeKind::WHEEL_BL_Z
        };
        break;
    default:
        found = false;
        break;
    }
    return found;
}

// - Conditions
enum ConditionKind
{
    NONE = -1,

    FREEWHEELING,
    WHEEL_CONTACTS,
    CHECKPOINTS,
    GEAR,

    COUNT // amount of condition kinds
}

const array<string> conditionNames =
{
    "Freewheeling",
    "Wheel Contacts",
    "Checkpoints",
    "Gear"
};

class Condition
{
    bool active;
}

array<Condition> conditions(ConditionKind::COUNT);
