// Wheel Lineup script

const string ID = "wheel_lineup";
const string NAME = "Wheel Lineup";
const string DESCRIPTION = "Tries to get a wheel as close to a point as possible.";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = DESCRIPTION;
    info.Version = "v2.0.0.0";
    return info;
}

void Main()
{
    OnRegister();
    RegisterBruteforceEvaluation(ID, NAME, OnEvaluate, OnSettings);
}

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string EVAL_FROM = PrefixVar("eval_from");
const string EVAL_TO = PrefixVar("eval_to");

const string POINT = PrefixVar("point");

const string MODE = PrefixVar("mode");

int evalFrom;
int evalTo;

vec3 point;

enum Wheel { FrontLeft, FrontRight, BackRight, BackLeft }
Wheel wheel;

const dictionary modes =
{
    {"Front Left", Wheel::FrontLeft},
    {"Front Right", Wheel::FrontRight},
    {"Back Right", Wheel::BackRight},
    {"Back Left", Wheel::BackLeft}
};
string mode;

void OnRegister()
{
    RegisterVariable(EVAL_FROM, 0);
    RegisterVariable(EVAL_TO, 10000);

    RegisterVariable(POINT, vec3().ToString());

    RegisterVariable(MODE, modes.GetKeys()[0]);

    evalFrom = int(GetVariableDouble(EVAL_FROM));
    evalTo = int(GetVariableDouble(EVAL_TO));

    point = Text::ParseVec3(GetVariableString(POINT));

    mode = GetVariableString(MODE);
    wheel = Wheel(modes[mode]);
}

void OnSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate From", EVAL_FROM);
    evalTo = UI::InputTimeVar("Evaluate To", EVAL_TO);
    evalTo = Math::Max(evalFrom, evalTo);
    SetVariable(EVAL_TO, evalTo);

    UI::DragFloat3Var("Point", POINT);
    point = Text::ParseVec3(GetVariableString(POINT));

    if (UI::BeginCombo("Wheels", mode))
    {
        const auto allModes = modes.GetKeys();
        for (uint i = 0; i < allModes.Length; i++)
        {
            const string newMode = allModes[i];
            if (UI::Selectable(newMode, mode == newMode))
            {
                wheel = Wheel(modes[newMode]);
                mode = newMode;
            }
        }

        UI::EndCombo();
    }
}

bool IsEvalTime(const int time)
{
    return time >= evalFrom && time <= evalTo;
}

bool IsAfterEvalTime(const int time)
{
    return time == evalTo + 10;
}

const float UNDEFINED = -1;
float current;
float best = UNDEFINED;

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    best = UNDEFINED;
}

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    BFEvaluationResponse@ const response = BFEvaluationResponse();
    switch (info.Phase)
    {
    case BFPhase::Initial:
        OnInitial(simManager, info.Iterations);
        break;
    case BFPhase::Search:
        response.Decision = OnSearch(simManager);
        break;
    }
    return response;
}

void OnInitial(SimulationManager@ simManager, uint iterations)
{
    const int time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        best = current;
    }
    else if (IsAfterEvalTime(time))
    {
        print("Best at " + iterations + ": " + best);
    }
}

BFEvaluationDecision OnSearch(SimulationManager@ simManager)
{
    BFEvaluationDecision decision = BFEvaluationDecision::DoNothing;

    const int time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        decision = BFEvaluationDecision::Accept;
    }
    else if (IsAfterEvalTime(time))
    {
        decision = BFEvaluationDecision::Reject;
    }

    return decision;
}

bool IsBetter(SimulationManager@ simManager)
{
    current = GetDistance(simManager);
    return current < best || best == UNDEFINED;
}

float GetDistance(SimulationManager@ simManager)
{
    const auto@ const state = simManager.SaveState();

    const iso4 loc = state.Dyna.CurrentState.Location;
    const vec3 pos = loc.Position;
    const mat3 rot = loc.Rotation;

    const auto@ const simWheels = state.Wheels;
    vec3 offset;
    switch (wheel)
    {
    case Wheel::FrontLeft:
        offset = simWheels.FrontLeft.SurfaceHandler.Location.Position;
        break;
    case Wheel::FrontRight:
        offset = simWheels.FrontRight.SurfaceHandler.Location.Position;
        break;
    case Wheel::BackRight:
        offset = simWheels.BackRight.SurfaceHandler.Location.Position;
        break;
    case Wheel::BackLeft:
        offset = simWheels.BackLeft.SurfaceHandler.Location.Position;
        break;
    }

    const vec3 wheelPosition = pos + RotateOffset(rot, offset);
    return Math::Distance(wheelPosition, point);
}

vec3 RotateOffset(const mat3 &in rot, const vec3 &in offset)
{
    return vec3(Math::Dot(offset, rot.x), Math::Dot(offset, rot.y), Math::Dot(offset, rot.z));
}
