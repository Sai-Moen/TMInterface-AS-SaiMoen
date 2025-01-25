const string ID = "finetuner";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Finetunes car properties w/ bruteforce";
    info.Version = "v2.1.1a";
    return info;
}

void Main()
{
    RegisterSettings();
    RegisterBruteforceEvaluation(ID, "Finetuner", OnEvaluate, RenderSettings);
}

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    BFEvaluationResponse response;

    const ms time = simManager.RaceTime;
    switch (info.Phase)
    {
    case BFPhase::Initial:
        break;
    case BFPhase::Search:
        break;
    }

    return response;
}

bool IsEvalTime(const int time)
{
    return evalFrom <= time && time <= evalTo;
}

bool IsPastEvalTime(const int time)
{
    return time > evalTo;
}

bool IsBetter(SimulationManager@ simManager)
{
    return false;
}