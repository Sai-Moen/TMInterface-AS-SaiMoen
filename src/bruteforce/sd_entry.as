// Entry Bruteforce script

const string ID = "sd_entry";
const string NAME = "SD Entry Helper";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = NAME;
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    OnRegister();
    RegisterBruteforceEvaluation(ID, NAME, OnEvaluate, OnSettings);
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
    Resize();
}

void OnSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate from", EVAL_FROM);
    evalTo = UI::InputTimeVar("Evaluate to", EVAL_TO);

    CapMax(EVAL_TO, evalFrom, evalTo);
    evalTo = ms(GetVariableDouble(EVAL_TO));
    Resize();
}

void Resize()
{
    const uint size = GetTickDiff(evalFrom, evalTo) + 1; // inclusive range so add 1
    if (size > 0xffff)
    {
        log("Large size detected, not resizing!", Severity::Warning);
        return;
    }

    scores.Resize(size);
}

void CapMax(const string &in variableName, const ms tfrom, const ms tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}

typedef float score;
score best;
array<score> scores;

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    auto@ const response = BFEvaluationResponse();

    const ms raceTime = simManager.RaceTime;
    if (IsEvalTime(raceTime))
    {
        const uint index = GetTickDiff(evalFrom, raceTime);
        scores[index] = GetScore(simManager);
    }
    else if (IsPastEvalTime(raceTime))
    {
        switch (info.Phase)
        {
        case BFPhase::Initial:
            if (IsAfterEvalTime(raceTime))
            {
                best = GetAverageScore(scores);
                print("Best at " + info.Iterations + " iterations is " + best);
                response.Decision = BFEvaluationDecision::Accept;
            }
            break;
        case BFPhase::Search:
            if (best < GetAverageScore(scores))
            {
                response.Decision = BFEvaluationDecision::Accept;
            }
            else
            {
                response.Decision = BFEvaluationDecision::Reject;
            }
            break;
        }
    }

    return response;
}

score GetScore(SimulationManager@ simManager)
{
    const auto@ const svc = simManager.SceneVehicleCar;
    return svc.IsSliding ? svc.TotalCentralForceAdded.z : 0;
}

score GetAverageScore(const array<score>@ const scores)
{
    score total = 0;

    const uint len = scores.Length;
    for (uint i = 0; i < len; i++)
    {
        total += scores[i];
    }

    return total / len;
}

bool IsEvalTime(const ms raceTime)
{
    return raceTime >= evalFrom && raceTime <= evalTo;
}

bool IsPastEvalTime(const ms raceTime)
{
    return raceTime > evalTo;
}

bool IsAfterEvalTime(const ms raceTime)
{
    return raceTime == evalTo + TICK;
}

uint GetTickDiff(const ms start, const ms end)
{
    return (end - start) / TICK;
}
