// API

interface IncMode
{
    bool SupportsUnlockedTimerange { get; }
    bool SupportsSaveStates { get; }

    void RenderSettings();

    void OnBegin(SimulationManager@);
    void OnStep(SimulationManager@);
    void OnEnd(SimulationManager@);
}

bool IncRegisterMode(const string &in name, IncMode@ imode)
{
    const bool success = Eval::modeNames.Find(name) == -1;
    if (success)
    {
        Eval::modeNames.Add(name);
        Eval::modes.Add(imode);
    }
    return success;
}

ms IncGetRelativeTime(SimulationManager@ simManager)
{
    return IncGetRelativeTime(simManager.TickTime);
}

ms IncGetRelativeTime(const ms absoluteTickTime)
{
    return absoluteTickTime - Eval::tInput;
}

void IncRewind(SimulationManager@ simManager)
{
    simManager.RewindToState(Eval::trailingState);
}
