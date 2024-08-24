
namespace SpeedDrift::Wiggle
{


const string VAR = SpeedDrift::VAR + "wiggle_";

const string ANGLE    = VAR + "angle";
const string POSITION = VAR + "position";

const double ANGLE_MIN = 0;
const double ANGLE_MAX = 45;

class WiggleContext
{
    double angle;
    double x;
    double y;
    double z;
}

WiggleContext wiggle;

void OnRegister()
{
    RegisterVariable(ANGLE, 15);
    RegisterVariable(POSITION, vec3().ToString());

    wiggle.angle = GetVariableDouble(ANGLE);
    const string position = GetVariableString(POSITION);
    vec3 v = Text::ParseVec3(position);
    wiggle.x = v.x;
    wiggle.y = v.y;
    wiggle.z = v.z;
}

void OnSettings()
{
    wiggle.angle = UI::SliderFloatVar("Maximum angle away from point", ANGLE, ANGLE_MIN, ANGLE_MAX);
    wiggle.angle = Math::Clamp(wiggle.angle, ANGLE_MIN, ANGLE_MAX);
    SetVariable(ANGLE, wiggle.angle);

    UI::DragFloat3Var("Point position", POSITION);
    vec3 v = Text::ParseVec3(GetVariableString(POSITION));
    wiggle.x = v.x;
    wiggle.y = v.y;
    wiggle.z = v.z;
}

void OnBegin(SimulationManager@ simManager)
{
}

void OnStep(SimulationManager@ simManager)
{
}


} // namespace SpeedDrift::Wiggle
