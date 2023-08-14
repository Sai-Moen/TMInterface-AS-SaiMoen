// Main Script, Strings everything together

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = "Incremental module";
    info.Description = "Contains: SD, Wallhug, maybe eventually something else in case of new ideas";
    info.Version = "v2.0.0.4";
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
        ModeDispatch(NONE::NAME, modeMap, mode);

        // Not the controller, execute an empty lambda
        @step = function(simManager, userCancelled) {};
        @end  = function(simManager, result) {};

        @changed = function(simManager, current, target) {};
        return;
    }

    simManager.RemoveStateValidation();
    ExecuteCommand(OPEN_EXTERNAL_CONSOLE);

    Eval::cmdlist.Content += simManager.InputEvents.ToCommandsText() + "\n\n";

    ModeDispatch(modeStr, modeMap, mode);

    if (Settings::evalRange)
    {
        @step = OnSimStepRangePre;

        Eval::Time::pre = Settings::timeFrom - TWO_TICKS;

        // Evaluating in descending order because that's easier to cleanup (do nothing)
        rangeOfTime.Resize(0);
        for (ms i = Settings::evalTo; i >= Settings::timeFrom; i -= TICK)
        {
            rangeOfTime.Add(i);
        }
        Eval::inputsResults.Resize(rangeOfTime.Length);
        Eval::Time::input = PopFromRange();
    }
    else
    {
        @step = OnSimStepSingle;

        Eval::inputsResults.Resize(1);
        Eval::Time::input = Settings::timeFrom;
    }
    @end = OnSimEndMain;
    @Eval::inputsResult = Eval::inputsResults[0];

    @changed = OnGameFinishMain;

    mode.OnBegin(simManager);
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    step(simManager, userCancelled);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    end(simManager, result);
}

void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target)
{
    changed(simManager, current, target);
}

// You are now leaving the TMInterface API

namespace Eval
{
    CommandList cmdlist;

    SimulationState@ minState; // The state saved when time equals min
    SimulationState@ MinState { get { return minState; } }

    void Rewind(SimulationManager@ simManager)
    {
        simManager.RewindToState(minState);
    }

    namespace Time
    {
        ms pre;   // When to save a state for a starting timerange
        ms min;   // When to save a state in order to be able to rewind to input time
        ms input; // When to do inputs for this iteration
        ms eval;  // When to check the results of a sub-iteration,
                  // may change within an iteration, but that is up to the implementing mode(s)

        void Update(const ms evalOffset)
        {
            min = input - TICK;
            eval = input + evalOffset;
        }

        bool LimitExceeded()
        {
            return input > Settings::timeTo;
        }
    }

    bool BeforeInput(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (time < Time::min) return true;
        else if (time == Time::min)
        {
            @minState = simManager.SaveState();
            return true;
        }
        return false;
    }

    bool IsInputTime(const ms time)
    {
        return time == Time::input;
    }

    bool IsEvalTime(const ms time)
    {
        return time == Time::eval;
    }

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
            if (inputs.IsEmpty()) return builder;

            InputCommand prev = inputs[0];
            builder += prev.ToScript() + "\n";
            for (uint i = 1; i < inputs.Length; i++)
            {
                InputCommand curr = inputs[i];
                if (curr.Type != prev.Type || curr.State != prev.State)
                {
                    builder += curr.ToScript() + "\n";
                }
                prev = curr;
            }
            return builder;
        }
    }

    uint irIndex = 0;
    InputsResult@ inputsResult;
    array<InputsResult> inputsResults;

    void Next()
    {
        @inputsResult = inputsResults[++irIndex];
        Eval::Time::input = PopFromRange();
    }

    void Reset()
    {
        cmdlist.Content = "";

        irIndex = 0;
        @inputsResult = null;
        inputsResults.Clear();
    }

    void Advance(SimulationManager@ simManager, const ms timestamp, const InputType type, const int state)
    {
        simManager.InputEvents.Add(timestamp, type, state);

        InputCommand cmd;
        cmd.Timestamp = timestamp;
        cmd.Type = type;
        cmd.State = state;
        inputsResult.AddInputCommand(cmd);

        Settings::PrintInfo(simManager, cmd.ToScript());

        Time::input += TICK;
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
    if (userCancelled || Eval::Time::LimitExceeded())
    {
        simManager.ForceFinish();
        return;
    }
    else if (Eval::BeforeInput(simManager)) return;

    mode.OnStep(simManager);
}

void OnSimStepRangePre(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled)
    {
        simManager.ForceFinish();
        return;
    }

    const ms time = simManager.TickTime;
    if (time < Eval::Time::pre) return;

    @rangeStart = simManager.SaveState();
    @step = OnSimStepRangeMain;
}

void OnSimStepRangeMain(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled)
    {
        simManager.ForceFinish();
        return;
    }
    else if (Eval::BeforeInput(simManager)) return;
    else if (Eval::Time::LimitExceeded())
    {
        if (rangeOfTime.IsEmpty())
        {
            simManager.ForceFinish();
            return;
        }

        Eval::Next();
        mode.OnBegin(simManager);

        simManager.RewindToState(rangeStart);
        return;
    }

    mode.OnStep(simManager);
}

funcdef void OnSimEnd(SimulationManager@ simManager, SimulationResult result);
const OnSimEnd@ end;

void OnSimEndMain(SimulationManager@ simManager, SimulationResult result)
{
    print("Simulation end", Severity::Success);

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

funcdef void OnGameFinish(SimulationManager@ simManager, int current, int target);
const OnGameFinish@ changed;

void OnGameFinishMain(SimulationManager@ simManager, int current, int target)
{
    simManager.PreventSimulationFinish();
}
