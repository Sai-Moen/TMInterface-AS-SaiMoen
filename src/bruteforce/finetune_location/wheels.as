namespace Wheels
{


const string FL = "Front Left Wheel";
const string FR = "Front Right Wheel";
const string BR = "Back Right Wheel";
const string BL = "Back Left Wheel";

void Main()
{
    bounds.Add(Group(boundsFL, FL, PREFIX + "fl_"));
    bounds.Add(Group(boundsFR, FR, PREFIX + "fr_"));
    bounds.Add(Group(boundsBR, BR, PREFIX + "br_"));
    bounds.Add(Group(boundsBL, BL, PREFIX + "bl_"));

    for (uint i = 0; i < modes.Length; i++)
    {
        ::modes.Add(modes[i]);
    }
    @modes = ::modes;
}

const string BOUND_PREFIX = ::BOUND_PREFIX + "wheel_";

const string BOUND_FL_X = BOUND_PREFIX + "fl_x";
const string BOUND_FL_Y = BOUND_PREFIX + "fl_y";
const string BOUND_FL_Z = BOUND_PREFIX + "fl_z";

const dictionary boundsFL =
{
    { BOUND_FL_X, @Bound(Kind::FL_X) },
    { BOUND_FL_Y, @Bound(Kind::FL_Y) },
    { BOUND_FL_Z, @Bound(Kind::FL_Z) }
};

const string BOUND_FR_X = BOUND_PREFIX + "fr_x";
const string BOUND_FR_Y = BOUND_PREFIX + "fr_y";
const string BOUND_FR_Z = BOUND_PREFIX + "fr_z";

const dictionary boundsFR =
{
    { BOUND_FR_X, @Bound(Kind::FR_X) },
    { BOUND_FR_Y, @Bound(Kind::FR_Y) },
    { BOUND_FR_Z, @Bound(Kind::FR_Z) }
};

const string BOUND_BR_X = BOUND_PREFIX + "br_x";
const string BOUND_BR_Y = BOUND_PREFIX + "br_y";
const string BOUND_BR_Z = BOUND_PREFIX + "br_z";

const dictionary boundsBR =
{
    { BOUND_BR_X, @Bound(Kind::BR_X) },
    { BOUND_BR_Y, @Bound(Kind::BR_Y) },
    { BOUND_BR_Z, @Bound(Kind::BR_Z) }
};

const string BOUND_BL_X = BOUND_PREFIX + "bl_x";
const string BOUND_BL_Y = BOUND_PREFIX + "bl_y";
const string BOUND_BL_Z = BOUND_PREFIX + "bl_z";

const dictionary boundsBL =
{
    { BOUND_BL_X, @Bound(Kind::BL_X) },
    { BOUND_BL_Y, @Bound(Kind::BL_Y) },
    { BOUND_BL_Z, @Bound(Kind::BL_Z) }
};

const string X = " X";
const string Y = " Y";
const string Z = " Z";

array<string>@ modes =
{
    FL + X, FL + Y, FL + Z,
    FR + X, FR + Y, FR + Z,
    BR + X, BR + Y, BR + Z,
    BL + X, BL + Y, BL + Z
};

bool GetValue(SimulationManager@ simManager, const Kind kind, const iso4 &in location, double &out value)
{
    const auto@ const wheels = simManager.Wheels;

    switch (kind)
    {
    case Kind::FL_X:
        value = AddOffsetToLocation(wheels.FrontLeft, location).x;
        break;
    case Kind::FL_Y:
        value = AddOffsetToLocation(wheels.FrontLeft, location).y;
        break;
    case Kind::FL_Z:
        value = AddOffsetToLocation(wheels.FrontLeft, location).z;
        break;
    case Kind::FR_X:
        value = AddOffsetToLocation(wheels.FrontRight, location).x;
        break;
    case Kind::FR_Y:
        value = AddOffsetToLocation(wheels.FrontRight, location).y;
        break;
    case Kind::FR_Z:
        value = AddOffsetToLocation(wheels.FrontRight, location).z;
        break;
    case Kind::BR_X:
        value = AddOffsetToLocation(wheels.BackRight, location).x;
        break;
    case Kind::BR_Y:
        value = AddOffsetToLocation(wheels.BackRight, location).y;
        break;
    case Kind::BR_Z:
        value = AddOffsetToLocation(wheels.BackRight, location).z;
        break;
    case Kind::BL_X:
        value = AddOffsetToLocation(wheels.BackLeft, location).x;
        break;
    case Kind::BL_Y:
        value = AddOffsetToLocation(wheels.BackLeft, location).y;
        break;
    case Kind::BL_Z:
        value = AddOffsetToLocation(wheels.BackLeft, location).z;
        break;
    default:
        return false;
    }

    return true;
}

vec3 AddOffsetToLocation(TM::SceneVehicleCar::SimulationWheel@ wheel, const iso4 &in location)
{
    const vec3 offset = wheel.SurfaceHandler.Location.Position;
    const mat3 rot = location.Rotation;
    const vec3 global = vec3(Math::Dot(offset, rot.x), Math::Dot(offset, rot.y), Math::Dot(offset, rot.z));
    return location.Position + global;
}


} // namespace Wheels
