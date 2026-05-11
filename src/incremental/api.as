interface IncIMode
{
    bool SingleIteration { get; }

    void Draw();

    void Begin(SimulationManager@);
    void Iteration(SimulationManager@);
    void Step(SimulationManager@);
    void End(SimulationManager@);
}

funcdef void OnDraw();

funcdef void OnBegin(SimulationManager@);
funcdef void OnIteration(SimulationManager@);
funcdef void OnStep(SimulationManager@);
funcdef void OnEnd(SimulationManager@);

class IncMode
{
    bool singleIteration;

    OnDraw@ draw;

    OnBegin@ begin;
    OnIteration@ iteration;
    OnStep@ step;
    OnEnd@ end;
}

bool IncRegisterMode(const string &in modeName, IncIMode@ imode)
{
    IncMode mode;
    mode.singleIteration = imode.SingleIteration;
    mode.draw = OnDraw(imode.Draw);
    mode.begin = OnBegin(imode.Begin);
    mode.iteration = OnIteration(imode.Iteration);
    mode.step = OnStep(imode.Step);
    mode.end = OnEnd(imode.End);
    return IncRegisterMode(modeName, mode);
}

bool IncRegisterMode(const string &in modeName, IncMode@ mode)
{
    if (Core::modeNames.Find(modeName) != -1)
        return false;

    Core::modeNames.Add(modeName);

    if (mode.draw is null) mode.draw = function() {};

    if (mode.begin is null)     mode.begin     = function(sim) {};
    if (mode.iteration is null) mode.iteration = function(sim) {};
    if (mode.step is null)      mode.step      = function(sim) {};
    if (mode.end is null)       mode.end       = function(sim) {};

    Core::modes.Add(mode);
    return true;
}

ms IncGetRelativeTime(SimulationManager@ sim)
{
    return Core::GetRelativeTime(sim.TickTime);
}

ms IncGetRelativeTime(const ms absoluteTime)
{
    return Core::GetRelativeTime(absoluteTime);
}

ms IncGetAbsoluteTime(const ms relativeTime)
{
    return Core::GetAbsoluteTime(relativeTime);
}

bool IncGetInput(SimulationManager@ sim, const InputType type, int &out value = void)
{
    return Core::GetInput(sim, Core::tInput, type, value);
}

bool IncGetInput(SimulationManager@ sim, const ms relativeTime, const InputType type, int &out value = void)
{
    return Core::GetInput(sim, Core::GetAbsoluteTime(relativeTime), type, value);
}

void IncSetInput(SimulationManager@ sim, const InputType type, const int value)
{
    Core::SetInput(sim, Core::tInput, type, value);
}

void IncSetInput(SimulationManager@ sim, const ms relativeTime, const InputType type, const int value)
{
    Core::SetInput(sim, Core::GetAbsoluteTime(relativeTime), type, value);
}

void IncRemoveInputs(
    SimulationManager@ sim,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    Core::RemoveInputs(sim, Core::tInput, type, value);
}

void IncRemoveInputs(
    SimulationManager@ sim,
    const ms relativeTime, const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    Core::RemoveInputs(sim, Core::GetAbsoluteTime(relativeTime), type, value);
}

void IncRemoveFromInputTime(SimulationManager@ sim, const array<InputType>@ inputTypes)
{
    Core::RemoveFromInputTime(sim, inputTypes);
}

SimulationState@ IncGetInputState()
{
    return Core::inputState;
}

void IncRewind(SimulationManager@ sim)
{
    // TODO: actual rewind semantics.
    RewindRemove(sim, Core::inputState);
}

class IncCommitContext
{
    protected uint present;
    protected array<int> analog;

    bool Get(const InputType inputType, int &out analogValue = void) const
    {
        if ((present & (1 << inputType)) == 0)
        {
            analogValue = 0;
            return false;
        }

        analogValue = analog[inputType];
        return true;
    }

    void Set(const InputType inputType, const int analogValue)
    {
        AssertLog(inputType >= 0, "Tried to allocate like 4GiB, do not pass negative values for inputType.");

        const uint index = inputType;
        present |= 1 << index;
        if (analog.Length <= index)
            analog.Resize(index + 1);
        analog[index] = analogValue;
    }
}

void IncCommit(SimulationManager@ sim, const IncCommitContext@ ctx = IncCommitContext())
{
    array<InputCommand> commands;

    const ms time = Core::tInput;
    // Note: just doing all input types for completeness I suppose, but we really only need the first half.
    for (uint i = 0; i < INPUT_TYPE_COUNT; ++i)
    {
        const InputType type = InputType(i);
        int value;
        if (!ctx.Get(type, value))
            continue;

        InputCommand cmd;
        cmd.Timestamp = time;
        cmd.Type = type;
        cmd.State = value;
        commands.Add(cmd);

        Core::SetInput(sim, time, type, value);
    }

    Core::Advance(commands);
}
