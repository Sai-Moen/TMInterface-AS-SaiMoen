// Speed Ladder; gradually increases eval timeframe during Speed Bruteforce

const string ID = "speed_ladder";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Speed Ladder Bruteforce";
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    OnRegister();
    RegisterBruteforceEvaluation(ID, "Speed Ladder", OnEvaluate, OnSettings);
}

void OnSimulationBegin(SimulationManager@)
{
    nextStep = limit;
    best = 0;
}

const string PREFIX = ID + "_";

const string LIMIT     = PREFIX + "limit";
const string OFFSET    = PREFIX + "offset";
const string EVAL_FROM = PREFIX + "eval_from";
const string EVAL_TO   = PREFIX + "eval_to";

typedef int ms;
const ms TICK = 10;

uint limit;
ms offset;
ms evalFrom;
ms evalTo;

void OnRegister()
{
    RegisterVariable(LIMIT, 5000);
    RegisterVariable(OFFSET, 50);
    RegisterVariable(EVAL_FROM, 0);
    RegisterVariable(EVAL_TO, 10000);

    limit    = uint(GetVariableDouble(LIMIT));
    offset   = ms(GetVariableDouble(OFFSET));
    evalFrom = ms(GetVariableDouble(EVAL_FROM));
    evalTo   = ms(GetVariableDouble(EVAL_TO));
}

void OnSettings()
{
    limit    = UI::InputIntVar("Iteration limit", LIMIT);
    offset   = UI::InputTimeVar("Time offset", OFFSET);
    evalFrom = UI::InputTimeVar("Evaluate from", EVAL_FROM);
    evalTo   = UI::InputTimeVar("Evaluate to", EVAL_TO);

    CapMax(EVAL_TO, evalFrom, evalTo);
    evalTo = ms(GetVariableDouble(EVAL_TO));
}

void CapMax(const string &in variableName, const ms tfrom, const ms tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}

uint nextStep;

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    BFEvaluationResponse response;

    const uint iterations = info.Iterations;
    if (iterations >= nextStep)
    {
        nextStep = iterations + limit;
        evalFrom += offset;
        evalTo += offset;

        print("Set eval timeframe to " + evalFrom + "-" + evalTo + ", next step at " + nextStep + " iterations");
    }

    switch (info.Phase)
    {
    case BFPhase::Initial:
        response.Decision = OnInitial(simManager, iterations);
        break;
    case BFPhase::Search:
        response.Decision = OnSearch(simManager);
        break;
    }

    return response;
}

double current;
double best;

ms bestTime;

BFEvaluationDecision OnInitial(SimulationManager@ simManager, uint iterations)
{
    BFEvaluationDecision decision = BFEvaluationDecision::DoNothing;

    const ms time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        best = current;
        bestTime = time;
    }
    else if (IsAfterEvalTime(time))
    {
        print("Best is " + PreciseFormat(best) + " @" + bestTime + "ms w/ " + iterations + " iterations");

        decision = IsSpeedCap(best) ? BFEvaluationDecision::Stop : BFEvaluationDecision::Accept;
    }

    return decision;
}

BFEvaluationDecision OnSearch(SimulationManager@ simManager)
{
    BFEvaluationDecision decision = BFEvaluationDecision::DoNothing;

    const ms time = simManager.RaceTime;
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
    current = simManager.Dyna.RefStateCurrent.LinearSpeed.Length() * 3.6;
    return current > best;
}

bool IsEvalTime(const ms time)
{
    return time >= evalFrom && time <= evalTo;
}

bool IsAfterEvalTime(const ms time)
{
    return time == evalTo + TICK;
}

string PreciseFormat(const double val)
{
    return Text::FormatFloat(val, "", 0, 6);
}

// need to simulate the floating point error in the game
const float speedCap = 1000.0f / 3.6f * 3.6f;

bool IsSpeedCap(const float val)
{
    return val >= speedCap;
}
