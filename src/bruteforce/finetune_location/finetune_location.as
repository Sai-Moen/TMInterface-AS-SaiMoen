// Finetunes the Location (Position and Rotation) of the car.

const string ID = "finetune_location";
const string TITLE = "Finetune Location";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    Wheels::Main();
    OnRegister();
    RegisterBruteforceEvaluation(ID, TITLE, OnEvaluate, OnSettings);
}

void OnDisabled()
{
    for (uint i = 0; i < bounds.Length; i++)
    {
        bounds[i].Save();
    }
}

const string PREFIX = ID + "_";

const string EVAL_FROM = PREFIX + "eval_from";
const string EVAL_TO   = PREFIX + "eval_to";

const string MODE   = PREFIX + "mode";
const string TARGET = PREFIX + "target";

int evalFrom;
int evalTo;

Kind mode;
double target;

void OnRegister()
{
    RegisterVariable(EVAL_FROM, 0);
    RegisterVariable(EVAL_TO, 0);
    evalFrom = int(GetVariableDouble(EVAL_FROM));
    evalTo = int(GetVariableDouble(EVAL_TO));

    RegisterVariable(MODE, Kind::NONE);
    RegisterVariable(TARGET, 0);
    mode = Kind(GetVariableDouble(MODE));
    target = GetVariableDouble(TARGET);

    for (uint i = 0; i < bounds.Length; i++)
    {
        bounds[i].Register();
    }
}

bool valid;
int impTime;

double current;
double best;

double diff;
double lowest;

void OnSimulationBegin(SimulationManager@)
{
    valid = false;
    impTime = -1;

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
        response.Decision = OnInitial(simManager, info.Iterations);
        break;
    case BFPhase::Search:
        response.Decision = OnSearch(simManager);
        break;
    }
    return response;
}

BFEvaluationDecision OnInitial(SimulationManager@ simManager, const uint iterations)
{
    BFEvaluationDecision decision = BFEvaluationDecision::DoNothing;

    const int time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        impTime = time;
        lowest = diff;
        best = current;
        valid = true;
    }
    else if (IsAfterEvalTime(time))
    {
        const string absolute = modes[mode] + ": " + PreciseFormat(best);
        const string relative = ", Difference: " + PreciseFormat(lowest);
        const string timestamp = ", Time: " + impTime;
        const string iter = ", Iterations: " + iterations;
        print(absolute + relative + timestamp + iter);

        decision = BFEvaluationDecision::Accept;
    }

    return decision;
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
    for (uint i = 0; i < bounds.Length; i++)
    {
        bounds[i].Validate(simManager);
    }

    if (!GetValue(simManager, mode, current)) return false;

    diff = Math::Abs(current - target);
    return diff < lowest || !valid;
}

void OnSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate From?", EVAL_FROM);
    evalTo = UI::InputTimeVar("Evaluate To?", EVAL_TO);
    CapMax(EVAL_TO, evalFrom, evalTo);

    ComboHelper("Target mode", modes[mode], modes, function(s) { SetVariable(MODE, mode = Kind(modes.Find(s))); } );
    target = UI::InputFloatVar("Target value", TARGET);

    for (uint i = 0; i < bounds.Length; i++)
    {
        Group@ const group = bounds[i];
        if (UI::CollapsingHeader(group.name))
        {
            DrawGroup(group);
        }
    }
}

void DrawGroup(Group@ const group)
{
    group.enabled = UI::CheckboxVar("Enable Group?", group.ENABLED);
    UI::BeginDisabled(!group.enabled);

    const auto@ const keys = group.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        Bound@ const bound = group.GetBound(key);
        DrawBound(bound);
    }

    UI::EndDisabled();
}

void DrawBound(Bound@ const bound)
{
    const string label = modes[bound.kind];

    UI::Separator();

    bound.enableLower = UI::Checkbox("Enable Lower " + label + " bound", bound.enableLower);
    UI::SameLine();
    bound.enableUpper = UI::Checkbox("Enable Upper " + label + " bound", bound.enableUpper);

    UI::PushItemWidth(192);

    UI::BeginDisabled(!bound.enableLower);
    UI::PushID(label + " Lower");
    bound.lower = UI::InputFloat("", bound.lower);
    UI::PopID();
    UI::EndDisabled();

    UI::SameLine();
    UI::TextDimmed(" < " + label + " < ");
    UI::SameLine();

    UI::BeginDisabled(!bound.enableUpper);
    UI::PushID(label + " Upper");
    bound.upper = UI::InputFloat("", bound.upper);
    UI::PopID();
    UI::EndDisabled();

    UI::PopItemWidth();

    UI::Separator();
}
