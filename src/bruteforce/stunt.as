// Stunt Bruteforce

const string ID = "bf_stunt";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Stunt Points Bruteforce";
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    OnRegister();
    RegisterBruteforceEvaluation(ID, "Stunt Bruteforce", OnEvaluate, OnSettings);
}

ms inputsMinTime;

void OnSimulationBegin(SimulationManager@)
{
    inputsMinTime = ms(GetVariableDouble("bf_inputs_min_time"));
    needStunt = true;
    best = 0;
}

const string PREFIX = ID + "_";

const string EVAL_FROM = PREFIX + "eval_from";
const string EVAL_TO   = PREFIX + "eval_to";

typedef int ms;
const ms TICK = 10;

ms evalFrom;
ms evalTo;

void OnRegister()
{
    RegisterVariable(EVAL_FROM, 0);
    RegisterVariable(EVAL_TO, 10000);

    evalFrom = ms(GetVariableDouble(EVAL_FROM));
    evalTo   = ms(GetVariableDouble(EVAL_TO));
}

void OnSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate from", EVAL_FROM);
    evalTo = UI::InputTimeVar("Evaluate to", EVAL_TO);

    CapMax(EVAL_TO, evalFrom, evalTo);
    evalTo = ms(GetVariableDouble(EVAL_TO));
}

void CapMax(const string &in variableName, const ms tfrom, const ms tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}

bool needStunt;
uint stunt;

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    BFEvaluationResponse response;

    switch (info.Phase)
    {
    case BFPhase::Initial:
        if (needStunt && IsBeforeInputsTime(simManager.RaceTime))
        {
            needStunt = false;
            stunt = simManager.PlayerInfo.StuntsScore;
        }
        response.Decision = OnInitial(simManager, info.Iterations);
        break;
    case BFPhase::Search:
        response.Decision = OnSearch(simManager);
        break;
    }

    if (response.Decision != BFEvaluationDecision::DoNothing)
    {
        simManager.PlayerInfo.StuntsScore = stunt;
    }

    return response;
}

uint current;
uint best;

BFEvaluationDecision OnInitial(SimulationManager@ simManager, uint iterations)
{
    BFEvaluationDecision decision = BFEvaluationDecision::DoNothing;

    const ms time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        best = current;
    }
    else if (IsAfterEvalTime(time))
    {
        print("Best is " + best + " at " + iterations + " iterations");

        decision = BFEvaluationDecision::Accept;
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
    current = simManager.PlayerInfo.StuntsScore;
    return current > best;
}

bool IsBeforeInputsTime(const ms time)
{
    return time + TICK == inputsMinTime;
}

bool IsEvalTime(const ms time)
{
    return time >= evalFrom && time <= evalTo;
}

bool IsAfterEvalTime(const ms time)
{
    return time == evalTo + TICK;
}
