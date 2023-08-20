// Main Script, Strings everything together

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = "Incremental module";
    info.Description = "Contains: SD, Wallhug, maybe eventually something else in case of new ideas";
    info.Version = "v2.0.0.5";
    return info;
}

void Main()
{
    OnRegister();
    PointCallbacksToEmpty();

    RegisterValidationHandler(ID, NAME, OnSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
    {
        ModeDispatch(NONE::NAME, modeMap, mode);
        return;
    }

    simManager.RemoveStateValidation();
    ExecuteCommand(OPEN_EXTERNAL_CONSOLE);

    auto@ const buffer = simManager.InputEvents;
    Eval::cmdlist.Content += buffer.ToCommandsText() + "\n\n";

    const uint duration = simManager.EventsDuration;
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Left);
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Right);

    ModeDispatch(modeStr, modeMap, mode);

    if (Settings::evalRange)
    {
        @step = OnSimStepRangePre;

        Eval::Time::pre = Settings::timeFrom - TWO_TICKS;

        Range::Start(buffer.Find(-1, InputType::Steer));
        Eval::inputsResults.Resize(Range::startingTimes.Length);
        Eval::Time::input = Range::Pop();
    }
    else
    {
        @step = OnSimStepSingle;

        Eval::inputsResults.Resize(1);
        Eval::Time::input = Settings::timeFrom;
    }
    @end = OnSimEndMain;
    @changed = OnGameFinishMain;
    @Eval::inputsResult = Eval::inputsResults[0];

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

dictionary modeMap;
const Mode@ mode;

void PointCallbacksToEmpty()
{
    @step = function(simManager, userCancelled) {};
    @end  = function(simManager, result) {};

    @changed = function(simManager, current, target) {};
}

namespace Range
{
    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("range_" + var);
    }

    const string MODE = PrefixVar("mode");

    string mode;

    dictionary map =
    {
        {"Speed", Speed},
        {"Horizontal Speed", HSpeed},
        {"Forwards Force", FForce}
    };
    array<string> modes = map.GetKeys();

    funcdef bool IsBetter(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other);
    const IsBetter@ isBetter;

    void ChangeMode(const string &in newMode)
    {
        @isBetter = cast<IsBetter>(map[newMode]);
        SetVariable(MODE, newMode);
        mode = newMode;
    }

    string GetBestInputs()
    {
        const Eval::InputsResult@ best = Eval::inputsResults[0];
        for (uint i = 1; i < Eval::inputsResults.Length; i++)
        {
            Eval::InputsResult@ const other = Eval::inputsResults[i];
            if (other.finalState is null) continue;

            if (best.finalState is null || isBetter(best, other))
            {
                @best = other;
            }
        }
        return best.ToString();
    }

    bool Speed(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other)
    {
        const vec3 vBest = best.finalState.SceneVehicleCar.CurrentLocalSpeed;
        const vec3 vOther = other.finalState.SceneVehicleCar.CurrentLocalSpeed;
        return vOther.LengthSquared() > vBest.LengthSquared();
    }

    bool HSpeed(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other)
    {
        const vec3 vBest = best.finalState.SceneVehicleCar.CurrentLocalSpeed;
        const vec3 vOther = other.finalState.SceneVehicleCar.CurrentLocalSpeed;
        return vOther.x * vOther.z > vBest.x * vBest.z;
    }

    bool FForce(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other)
    {
        const vec3 vBest = best.finalState.SceneVehicleCar.TotalCentralForceAdded;
        const vec3 vOther = other.finalState.SceneVehicleCar.TotalCentralForceAdded;
        return vOther.z > vBest.z;
    }

    array<ms> startingTimes;
    const array<uint>@ startingIndices;
    SimulationState@ startingState;

    ms Pop()
    {
        ms first = startingTimes[0];
        startingTimes.RemoveAt(0);
        return first;
    }

    void Start(const array<uint>@ const indices)
    {
        @Range::startingIndices = indices;

        // Evaluating in descending order because that's easier to cleanup (do nothing)
        Range::startingTimes.Resize(0);
        for (ms i = Settings::evalTo; i >= Settings::timeFrom; i -= TICK)
        {
            Range::startingTimes.Add(i);
        }
    }

    void ApplyIndices(TM::InputEventBuffer@ const buffer)
    {
        for (uint i = 0; i < startingIndices.Length; i++)
        {
            buffer.Add(buffer[startingIndices[i]]);
        }
    }

    void Reset()
    {
        @startingIndices = null;
        @startingState = null;
    }
}

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
        SimulationState@ finalState;

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

    void NextRangeTime(SimulationManager@ simManager)
    {
        EndRangeTime(simManager);
        @inputsResult = inputsResults[++irIndex];
        Time::input = Range::Pop();
    }

    void EndRangeTime(SimulationManager@ simManager)
    {
        @inputsResult.finalState = simManager.SaveState();
    }

    bool up;
    bool down;
    bool respawn;

    void Reset()
    {
        cmdlist.Content = "";

        irIndex = 0;
        @inputsResult = null;
        inputsResults.Clear();

        up = false;
        down = false;
        respawn = false;
    }

    void Advance(SimulationManager@ simManager, const int state)
    {
        const ms timestamp = Eval::Time::input;
        const InputType type = InputType::Steer;

        const auto@ const buffer = simManager.InputEvents;
        BufferRemoveIndices(buffer, buffer.Find(timestamp, type));

        SaveExistingInput(buffer, timestamp, InputType::Respawn, respawn);
        SaveExistingInput(buffer, timestamp, InputType::Up, up);
        SaveExistingInput(buffer, timestamp, InputType::Down, down);
        buffer.Add(timestamp, type, state);

        InputCommand cmd = MakeInputCommand(timestamp, type, state);
        inputsResult.AddInputCommand(cmd);
        Settings::PrintInfo(simManager, cmd.ToScript());

        Time::input += TICK;
    }

    void SaveExistingInput(
        TM::InputEventBuffer@ const buffer,
        const int time,
        const InputType type,
        const bool current)
    {
        const int state = current ? 1 : 0;
        if (DiffPreviousInput(buffer, time, type, current))
            inputsResult.AddInputCommand(MakeInputCommand(time, type, state));
    }
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

    @Range::startingState = simManager.SaveState();
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
        if (Range::startingTimes.IsEmpty())
        {
            Eval::EndRangeTime(simManager);
            simManager.ForceFinish();
            return;
        }

        print("");

        Range::ApplyIndices(simManager.InputEvents);
        Eval::NextRangeTime(simManager);
        mode.OnBegin(simManager);

        simManager.RewindToState(Range::startingState);
        return;
    }

    mode.OnStep(simManager);
}

funcdef void OnSimEnd(SimulationManager@ simManager, SimulationResult result);
const OnSimEnd@ end;

void OnSimEndMain(SimulationManager@ simManager, SimulationResult result)
{
    print("Simulation end", Severity::Success);

    Eval::cmdlist.Content += Range::GetBestInputs();
    if (Eval::cmdlist.Save(FILENAME))
    {
        log("Inputs saved!", Severity::Success);
    }
    else
    {
        log("Inputs not saved.", Severity::Error);
    }
    Eval::Reset();

    Range::Reset();
    PointCallbacksToEmpty();
}

funcdef void OnGameFinish(SimulationManager@ simManager, int current, int target);
const OnGameFinish@ changed;

void OnGameFinishMain(SimulationManager@ simManager, int current, int target)
{
    simManager.PreventSimulationFinish();
}
