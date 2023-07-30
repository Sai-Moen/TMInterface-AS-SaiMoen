// Main Script, Strings everything together

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = INFO_AUTHOR;
    info.Name = INFO_NAME;
    info.Description = INFO_DESCRIPTION;
    info.Version = INFO_VERSION;
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
        ModeDispatch(MODE_NONE_NAME, modeMap, mode);

        // Not the controller, execute an empty lambda
        @step = function(simManager, userCancelled){};
        return;
    }

    // simManager.RemoveStateValidation();

    @eventBuffer = simManager.InputEvents;
    
    ModeDispatch(modeStr, modeMap, mode);

    if (evalRange)
    {
        @step = OnSimStepRangePre;

        // Evaluating in descending order because that's easier to cleanup (do nothing)
        rangeOfTime.Resize(0);
        for (ms i = evalTo; i >= timeFrom; i -= TICK)
        {
            rangeOfTime.Add(i);
        }
        inputTime = FirstFromRange();
    }
    else
    {
        @step = OnSimStepSingle;

        inputTime = timeFrom;
    }

    mode.OnSimulationBegin(simManager);
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    step(simManager, userCancelled);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    TM::InputEventBuffer@ const buffer = eventBuffer;
    @eventBuffer = null;
    if (IsOtherController()) return;

    CommandList commands;
    commands.Content = buffer.ToCommandsText();

    // What is this
    auto option = CommandListProcessOption(0);
    commands.Process(option);

    if (commands.Save(FILENAME))
    {
        log("Inputs saved!", Severity::Success);
    }
    else
    {
        log("Inputs not saved.", Severity::Error);
    }
}

// You are now leaving the TMInterface API

dictionary modeMap;
const Mode@ mode;

TM::InputEventBuffer@ eventBuffer;

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

// OnSimStep stuff
ms inputTime;
SimulationState@ rangeStart;
array<ms> rangeOfTime;

funcdef void OnSimStep(SimulationManager@ simManager, bool userCancelled);
const OnSimStep@ step;

void OnSimStepSingle(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled || inputTime > timeTo) return;

    mode.OnSimulationStep(simManager);
}

void OnSimStepRangePre(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled) return;

    const ms time = simManager.RaceTime;
    if (time == timeFrom - TWO_TICKS)
    {
        @rangeStart = simManager.SaveState();
        @step = OnSimStepRangeMain;
    }
}

void OnSimStepRangeMain(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled) return;
    else if (inputTime > timeTo)
    {
        if (rangeOfTime.Length == 0) return;
        inputTime = FirstFromRange();

        simManager.RewindToState(rangeStart);
        return;
    }

    mode.OnSimulationStep(simManager);
}
