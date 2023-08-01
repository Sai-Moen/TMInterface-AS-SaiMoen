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
    Eval::cmdlist.Content += simManager.InputEvents.ToCommandsText() + "\n\n";

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
        Eval::inputsResults.Resize(rangeOfTime.Length);
        Eval::inputTime = PopFromRange();
    }
    else
    {
        @step = OnSimStepSingle;

        Eval::inputsResults.Resize(1);
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

    Eval::cmdlist.Content += Eval::GetBestInputs();
    if (Eval::cmdlist.Save(FILENAME))
    {
        log("Inputs saved!", Severity::Success);
    }
    else
    {
        log("Inputs not saved.", Severity::Error);
    }

    Eval::Reset();
}

// You are now leaving the TMInterface API

namespace Eval
{
    CommandList cmdlist;

    ms inputTime;
    bool TimeLimitExceeded()
    {
        return inputTime > Settings::timeTo;
    }
    bool isEnded;

    class InputsResult
    {
        array<InputCommand> inputs;
        TM::SceneVehicleCar@ finalState;

        void AddInputCommand(const InputCommand &in cmd)
        {
            inputs.Add(cmd);
        }

        string ToString() const
        {
            string builder;
            for (uint i = 0; i < inputs.Length; i++)
            {
                builder += inputs[i].ToScript() + "\n";
            }
            return builder;
        }
    }

    uint irIndex = 0;
    array<InputsResult> inputsResults;

    void Next()
    {
        irIndex++;
        Eval::inputTime = PopFromRange();
    }

    void Reset()
    {
        cmdlist.Content = "";
        Eval::isEnded = false;

        irIndex = 0;
        inputsResults.Clear();
    }

    void AddInput(ms timestamp, InputType type, int state)
    {
        InputCommand cmd;
        cmd.Timestamp = timestamp;
        cmd.Type = type;
        cmd.State = state;
        inputsResults[irIndex].AddInputCommand(cmd);
    }

    funcdef bool IsBetter(const InputsResult@ const best, const InputsResult@ const other);
    string GetBestInputs()
    {
        const InputsResult@ best = inputsResults[0];
        for (uint i = 1; i < inputsResults.Length; i++)
        {
            const InputsResult@ const other = inputsResults[i];
            if (Settings::isBetter(best, other))
            {
                @best = other;
            }
        }
        return best.ToString();
    }
}

dictionary modeMap;
const Mode@ mode;

array<ms> rangeOfTime;
SimulationState@ rangeStart;

ms PopFromRange()
{
    ms first = rangeOfTime[0];
    rangeOfTime.RemoveAt(0);
    return first;
}

funcdef void OnSimStep(SimulationManager@ simManager, bool userCancelled);
const OnSimStep@ step;

void OnSimStepSingle(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled || Eval::isEnded) return;
    else if (Eval::TimeLimitExceeded())
    {
        Eval::isEnded = true;
        return;
    }

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
    if (userCancelled || Eval::isEnded) return;
    else if (Eval::TimeLimitExceeded())
    {
        if (rangeOfTime.IsEmpty())
        {
            Eval::isEnded = true;
            return;
        }

        Eval::Next();

        simManager.RewindToState(rangeStart);
        return;
    }

    mode.OnSimulationStep(simManager);
}
