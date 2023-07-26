// Main Script, Strings everything together

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.name = INFO_NAME;
    info.author = INFO_AUTHOR;
    info.version = INFO_VERSION;
    info.description = INFO_DESCRIPTION;
    return info;
}

void Main()
{
    OnRegister();
    RegisterValidationHandler(ID, NAME, OnSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
    {
        ScriptDispatch(MODE_NONE);

        // Not the controller, execute an empty lambda
        @step = function(simManager, userCancelled) {};
        return;
    }

    ScriptDispatch();

    if (evalRange)
    {
        @step = OnSimStepRangePre;

        // Evaluating in descending order because that's easier to cleanup (do nothing)
        rangeOfTime.Resize(0);
        for (ms i = evalTo; i >= timeFrom; i -= TICK)
        {
            rangeOfTime.InsertLast(i);
        }
        inputTime = FirstFromRange();
    }
    else
    {
        @step = OnSimStepSingle;

        inputTime = timeFrom;
    }

    script.OnSimulationBegin(simManager);
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    step(simManager, userCancelled);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    if (IsOtherController()) return;

    // get inputs
}

// You are now leaving the TMInterface API

bool IsOtherController()
{
    return ID != GetVariableString(CONTROLLER);
}

ms FirstFromRange()
{
    ms first = rangeOfTime[0];
    rangeOfTime.RemoveAt(0);
    return first;
}

// SimStep stuff
ms inputTime;
SimulationState@ rangeStart;
array<ms> rangeOfTime;

void OnSimStepSingle(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled || inputTime > timeTo) return;

    script.OnSimulationStep(simManager);
}

void OnSimStepRangePre(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled) return;

    const ms time = simManager.get_RaceTime();
    if (time == timeFrom - TWO_TICKS)
    {
        @rangeStart = simManager.SaveState();
        @step = OnSimStepRange;
    }
}

void OnSimStepRange(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled) return;
    else if (inputTime > timeTo)
    {
        if (rangeOfTime.Length == 0) return;
        inputTime = FirstFromRange();

        simManager.RewindToState(rangeStart);
        return;
    }

    script.OnSimulationStep(simManager);
}
