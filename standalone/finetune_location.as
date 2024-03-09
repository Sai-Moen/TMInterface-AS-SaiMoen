// Finetunes the Location (Position and Rotation) of the car.

const string ID = "finetune_location";
const string TITLE = "Finetune Location";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v2.0.1.1";
    return info;
}

void Main()
{
    OnRegister();
    RegisterBruteforceEvaluation(ID, TITLE, OnEvaluate, OnSettings);
}

void OnDisabled()
{
    const array<string>@ const keys = bounds.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        SetVariable(key, string(BoundsCast(key)));
    }
}

const string PREFIX = ID + "_";

const string EVAL_FROM = PREFIX + "eval_from";
const string EVAL_TO =   PREFIX + "eval_to";

const string MODE =   PREFIX + "mode";
const string TARGET = PREFIX + "target";

const string BOUND_X =     PREFIX + "bound_x";
const string BOUND_Y =     PREFIX + "bound_y";
const string BOUND_Z =     PREFIX + "bound_z";
const string BOUND_YAW =   PREFIX + "bound_yaw";
const string BOUND_PITCH = PREFIX + "bound_pitch";
const string BOUND_ROLL =  PREFIX + "bound_roll";
const string BOUND_SPEED = PREFIX + "bound_speed";

enum Kind
{
    NONE,
    X, Y, Z,
    YAW, PITCH, ROLL,
    SPEED,
}

class Bound
{
    protected const string SEP { get const { return " "; } }

    Bound(const Kind k)
    {
        kind = k;
    }

    Kind kind;

    bool enableLower;
    double lower;

    bool enableUpper;
    double upper;

    bool InRange(TM::HmsStateDyna@ const dyna) const
    {
        double value;
        if (GetValue(dyna, kind, value)) return (!enableLower || lower < value) && (!enableUpper || value < upper);
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
        const array<string>@ const a = s.Split(SEP);
        if (a.Length != 2) return;

        lower = Text::ParseFloat(a[0]);
        upper = Text::ParseFloat(a[1]);
    }
}

bool GetValue(TM::HmsStateDyna@ const dyna, const Kind kind, double &out value)
{
    const iso4 location = dyna.Location;
    const vec3 position = location.Position;
    mat3 rotation = location.Rotation;

    float yaw;
    float pitch;
    float roll;

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
        return false;
    }
    return true;
}

int evalFrom;
int evalTo;

Kind mode;
double target;

const array<string> modes =
{
    "", "X", "Y", "Z", "Yaw", "Pitch", "Roll", "Speed"
};

const dictionary bounds =
{
    { BOUND_X,     @Bound(Kind::X)     },
    { BOUND_Y,     @Bound(Kind::Y)     },
    { BOUND_Z,     @Bound(Kind::Z)     },
    { BOUND_YAW,   @Bound(Kind::YAW)   },
    { BOUND_PITCH, @Bound(Kind::PITCH) },
    { BOUND_ROLL,  @Bound(Kind::ROLL)  },
    { BOUND_SPEED, @Bound(Kind::SPEED) }
};

Bound@ BoundsCast(const string &in key)
{
    return cast<Bound@>(bounds[key]);
}

void OnRegister()
{
    RegisterVariable(EVAL_FROM, int(0));
    RegisterVariable(EVAL_TO, int(0));
    evalFrom = int(GetVariableDouble(EVAL_FROM));
    evalTo = int(GetVariableDouble(EVAL_TO));

    RegisterVariable(MODE, Kind(0));
    RegisterVariable(TARGET, double(0));
    mode = Kind(GetVariableDouble(MODE));
    target = GetVariableDouble(TARGET);

    const array<string>@ const keys = bounds.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        RegisterVariable(key, string());
        BoundsCast(key).FromString(GetVariableString(key));
    }
}

bool valid;

double current;
double best;

double diff;
double lowest;

void OnSimulationBegin(SimulationManager@)
{
    valid = false;

    current = 0;
    best = 0;

    diff = 0;
    lowest = 0;
}

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    BFEvaluationResponse response;

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

void OnInitial(SimulationManager@ simManager, const uint iterations)
{
    const int time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        lowest = diff;
        best = current;
        valid = true;
    }
    else if (IsAfterEvalTime(time))
    {
        print("Best at " + iterations + ": " + Text::FormatFloat(best, " ", 0, 16));
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
    else if (IsPastEvalTime(time))
    {
        decision = BFEvaluationDecision::Reject;
    }

    return decision;
}

bool IsEvalTime(const int time)
{
    return evalFrom <= time && time <= evalTo;
}

bool IsAfterEvalTime(const int time)
{
    return time == evalTo + 10;
}

bool IsPastEvalTime(const int time)
{
    return time > evalTo;
}

bool IsBetter(SimulationManager@ simManager)
{
    TM::HmsStateDyna@ const dyna = simManager.Dyna.CurrentState;

    const array<string>@ const keys = bounds.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        if (!BoundsCast(keys[i]).InRange(dyna)) return false;
    }

    if (!GetValue(dyna, mode, current)) return false;

    diff = Math::Abs(current - target);
    return diff < lowest || !valid;
}

Bound@ active;

void OnSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate From?", EVAL_FROM);
    evalTo = UI::InputTimeVar("Evaluate To?", EVAL_TO);
    CapMax(EVAL_TO, evalFrom, evalTo);

    ComboHelper("Target mode", modes[mode], modes, function(s) { SetVariable(MODE, mode = Kind(Find(modes, s))); } );
    target = UI::InputFloatVar("Target value", TARGET);

    const array<string>@ const keys = bounds.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        @active = BoundsCast(key);
        DrawBound();
        SetVariable(key, string(active));
    }
    @active = null;
}

void DrawBound()
{
    const string label = modes[active.kind];

    UI::Separator();

    active.enableLower = UI::Checkbox("Enable Lower " + label + " bound", active.enableLower);
    UI::SameLine();
    active.enableUpper = UI::Checkbox("Enable Upper " + label + " bound", active.enableUpper);

    UI::PushItemWidth(192);

    UI::BeginDisabled(!active.enableLower);
    UI::PushID(label + " Lower");
    active.lower = UI::InputFloat("", active.lower);
    UI::PopID();
    UI::EndDisabled();

    UI::SameLine();
    UI::TextDimmed(" < " + label + " < ");
    UI::SameLine();

    UI::BeginDisabled(!active.enableUpper);
    UI::PushID(label + " Upper");
    active.upper = UI::InputFloat("", active.upper);
    UI::PopID();
    UI::EndDisabled();

    UI::PopItemWidth();

    UI::Separator();
}

// For some reason array<string>.Find does not work...
int Find(const array<string>@ const a, const string &in s)
{
    for (uint i = 0; i < a.Length; i++)
    {
        if (a[i] == s) return i;
    }
    return -1;
}

funcdef void OnNewMode(const string &in);

bool ComboHelper(
    const string &in label,
    const string &in currentMode,
    const array<string>@ const allModes,
    const OnNewMode@ const onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, currentMode);
    if (isOpen)
    {
        for (uint i = 0; i < allModes.Length; i++)
        {
            const string newMode = allModes[i];
            if (UI::Selectable(newMode, currentMode == newMode))
            {
                onNewMode(newMode);
            }
        }

        UI::EndCombo();
    }
    return isOpen;
}

void CapMax(const string &in variableName, const int tfrom, const int tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}
