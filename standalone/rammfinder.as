// Rammstein finding script

const string ID = "ramm_finder";
const string NAME = "RammFinder";
const string DESCRIPTION = "Finds a ramm within the evaluation timerange";

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

const string FRONT_LEFT = PrefixVar("front_left");
const string FRONT_RIGHT = PrefixVar("front_right");
const string BACK_RIGHT = PrefixVar("back_right");
const string BACK_LEFT = PrefixVar("back_left");

int evalFrom;
int evalTo;

enum Wheel { FrontLeft, FrontRight, BackRight, BackLeft, Count }
const array<string> wheels = {"Front Left", "Front Right", "Back Right", "Back Left"};

const string WHEEL_NONE = "None";
enum WheelState { None, Grounded, Lifted }
const dictionary wheelStatesMap =
{
    {WHEEL_NONE, WheelState::None},
    {"Grounded", WheelState::Grounded},
    {"Lifted", WheelState::Lifted}
};
array<string> wheelModes(Wheel::Count);
array<int> wheelStates(Wheel::Count);

int GetState(const Wheel wheel)
{
    return int(wheelStatesMap[wheelModes[wheel]]);
}

void OnRegister()
{
    RegisterVariable(EVAL_FROM, 0);
    RegisterVariable(EVAL_TO, 10000);

    RegisterVariable(FRONT_LEFT, WHEEL_NONE);
    RegisterVariable(FRONT_RIGHT, WHEEL_NONE);
    RegisterVariable(BACK_RIGHT, WHEEL_NONE);
    RegisterVariable(BACK_LEFT, WHEEL_NONE);

    evalFrom = int(GetVariableDouble(EVAL_FROM));
    evalTo = int(GetVariableDouble(EVAL_TO));

    wheelModes[Wheel::FrontLeft] = GetVariableString(FRONT_LEFT);
    wheelModes[Wheel::FrontRight] = GetVariableString(FRONT_RIGHT);
    wheelModes[Wheel::BackRight] = GetVariableString(BACK_RIGHT);
    wheelModes[Wheel::BackLeft] = GetVariableString(BACK_LEFT);

    for (Wheel i = Wheel(0); i < Wheel::Count; i++)
    {
        wheelStates[i] = GetState(i);
    }
}

void OnSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate From", EVAL_FROM);
    evalTo = UI::InputTimeVar("Evaluate To", EVAL_TO);
    evalTo = Math::Max(evalFrom, evalTo);
    SetVariable(EVAL_TO, evalTo);

    const array<string>@ const allModes = wheelStatesMap.GetKeys();
    for (Wheel i = Wheel(0); i < Wheel::Count; i++)
    {
        const string currentMode = wheelModes[i];
        if (UI::BeginCombo(wheels[i], currentMode))
        {
            for (uint j = 0; j < allModes.Length; j++)
            {
                const string newMode = allModes[j];
                if (UI::Selectable(newMode, currentMode == newMode))
                {
                    wheelModes[i] = newMode;
                    wheelStates[i] = GetState(i);
                }
            }

            UI::EndCombo();
        }
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
    const auto@ const state = simManager.SaveState();
    const auto@ const simWheels = state.Wheels;

    for (Wheel i = Wheel(0); i < Wheel::Count; i++)
    {
        bool groundedness;
        switch (i)
        {
        case Wheel::FrontLeft:
            groundedness = simWheels.FrontLeft.RTState.HasGroundContact;
            break;
        case Wheel::FrontRight:
            groundedness = simWheels.FrontRight.RTState.HasGroundContact;
            break;
        case Wheel::BackRight:
            groundedness = simWheels.BackRight.RTState.HasGroundContact;
            break;
        case Wheel::BackLeft:
            groundedness = simWheels.BackLeft.RTState.HasGroundContact;
            break;
        }

        switch (wheelStates[i])
        {
        case WheelState::None:
            break;
        case WheelState::Grounded:
            if (!groundedness) return false;
            break;
        case WheelState::Lifted:
            if (groundedness) return false;
            break;
        }
    }

    current = GetHeight(simManager);
    return current < best || best == UNDEFINED;
}

float GetHeight(SimulationManager@ simManager)
{
    const auto@ const state = simManager.SaveState();

    const iso4 loc = state.Dyna.CurrentState.Location;
    const vec3 pos = loc.Position;
    const mat3 rot = loc.Rotation;

    const auto@ const simWheels = state.Wheels;
    const float yfl = RotateOffset(rot, simWheels.FrontLeft.SurfaceHandler.Location.Position).y;
    const float yfr = RotateOffset(rot, simWheels.FrontRight.SurfaceHandler.Location.Position).y;
    const float ybr = RotateOffset(rot, simWheels.BackRight.SurfaceHandler.Location.Position).y;
    const float ybl = RotateOffset(rot, simWheels.BackLeft.SurfaceHandler.Location.Position).y;

    return pos.y + Math::Max(Math::Max(yfl, yfr), Math::Max(ybr, ybl));
}

vec3 RotateOffset(const mat3 &in rot, const vec3 &in offset)
{
    return vec3(Math::Dot(offset, rot.x), Math::Dot(offset, rot.y), Math::Dot(offset, rot.z));
}
