// Main Script, Strings everything together

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = INFO::AUTHOR;
    info.Name = INFO::NAME;
    info.Description = INFO::DESCRIPTION;
    info.Version = INFO::VERSION;
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

    simManager.RemoveStateValidation();

    @Eval::buffer = simManager.InputEvents;
    
    ModeDispatch(modeStr, modeMap, mode);

    if (Settings::evalRange)
    {
        @step = OnSimStepRangePre;

        // Evaluating in descending order because that's easier to cleanup (do nothing)
        rangeOfTime.Resize(0);
        for (ms i = Settings::evalTo; i >= Settings::timeFrom; i -= TICK)
        {
            rangeOfTime.Add(i);
        }
        Eval::inputTime = FirstFromRange();
    }
    else
    {
        @step = OnSimStepSingle;

        Eval::inputTime = Settings::timeFrom;
    }

    mode.OnSimulationBegin(simManager);
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    step(simManager, userCancelled);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    if (IsOtherController()) return;

    const ms finalTime = Settings::timeTo + Eval::SEEK_MAX;
    for (ms i = Settings::timeFrom; i <= finalTime; i += TICK)
    {
        array<uint>@ indices = Eval::buffer.Find(i, InputType::Steer);
        for (int j = indices.Length - 2; j >= 0; j--)
        {
            Eval::buffer.RemoveAt(indices[j]);
        }
    }

    CommandList commands;
    commands.Content = Eval::buffer.ToCommandsText();
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
namespace Eval
{
    const ms SEEK_MAX = 1200;

    ms inputTime;
    TM::InputEventBuffer@ buffer;

    bool TimeLimitExceeded()
    {
        return inputTime > Settings::timeTo;
    }
}

dictionary modeMap;
const Mode@ mode;

SimulationState@ rangeStart;
array<ms> rangeOfTime;

funcdef void OnSimStep(SimulationManager@ simManager, bool userCancelled);
const OnSimStep@ step;

void OnSimStepSingle(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled || Eval::TimeLimitExceeded()) return;

    mode.OnSimulationStep(simManager);
}

void OnSimStepRangePre(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled) return;

    const ms time = simManager.TickTime;
    if (time == Settings::timeFrom - TWO_TICKS)
    {
        @rangeStart = simManager.SaveState();
        @step = OnSimStepRangeMain;
    }
}

void OnSimStepRangeMain(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled) return;
    else if (Eval::TimeLimitExceeded())
    {
        if (rangeOfTime.Length == 0) return;
        Eval::inputTime = FirstFromRange();

        simManager.RewindToState(rangeStart);
        return;
    }

    mode.OnSimulationStep(simManager);
}
