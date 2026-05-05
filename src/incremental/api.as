interface IncIMode
{
    bool SupportsUnlockedTimerange { get; }

    void RenderSettings();

    void Begin(SimulationManager@);
    void Step(SimulationManager@);
    void End(SimulationManager@);
}

funcdef void OnEvent();
funcdef void OnSim(SimulationManager@);

class IncMode
{
    bool supportsUnlockedTimerange;

    OnEvent@ renderSettings;

    OnSim@ begin;
    OnSim@ step;
    OnSim@ end;
}

bool IncRegisterMode(const string &in modeName, IncIMode@ imode)
{
    IncMode mode;
    mode.supportsUnlockedTimerange = imode.SupportsUnlockedTimerange;
    mode.renderSettings = OnEvent(imode.RenderSettings);
    mode.begin = OnSim(imode.Begin);
    mode.step = OnSim(imode.Step);
    mode.end = OnSim(imode.End);
    return IncRegisterMode(modeName, mode);
}

bool IncRegisterMode(const string &in modeName, IncMode@ mode)
{
    if (Core::modeNames.Find(modeName) != -1)
        return false;

    Core::modeNames.Add(modeName);
    Core::modes.Add(mode);
    return true;
}

ms IncGetRelativeTime(SimulationManager@ sim)
{
    return IncGetRelativeTime(sim.TickTime);
}

ms IncGetRelativeTime(const ms absoluteTickTime)
{
    return absoluteTickTime - Core::tInput;
}

ms IncGetAbsoluteTime(const ms relativeTickTime)
{
    return Core::tInput + relativeTickTime;
}

void IncSetInput(SimulationManager@ sim, const InputType type, const int value)
{
    Core::SetInput(sim, Core::tInput, type, value);
}

void IncSetInput(SimulationManager@ sim, const ms relativeTime, const InputType type, const int value)
{
    Core::SetInput(sim, IncGetAbsoluteTime(relativeTime), type, value);
}

bool IncHasInputs(
    SimulationManager@ sim,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    return Core::HasInputs(sim, Core::tInput, type, value);
}

bool IncHasInputs(
    SimulationManager@ sim,
    const ms relativeTime, const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    return Core::HasInputs(sim, IncGetAbsoluteTime(relativeTime), type, value);
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
    Core::RemoveInputs(sim, IncGetAbsoluteTime(relativeTime), type, value);
}

void IncRemoveSteeringAhead(SimulationManager@ sim)
{
    Core::RemoveSteeringAhead(sim);
}

SimulationState@ IncGetTrailingState()
{
    return Core::trailingState;
}

void IncRewind(SimulationManager@ sim)
{
    RewindRemove(sim, Core::trailingState);
}

class IncCommitContext
{
    protected uint present;
    protected array<int> analog;

    bool Get(const InputType inputType, int &out analogValue = 0) const
    {
        if ((present & (1 << inputType)) == 0)
            return false;

        analogValue = analog[inputType];
        return true;
    }

    void Set(const InputType inputType, const int analogValue)
    {
        AssertLog(inputType >= 0, "Tried to allocate like 4GiB, do not pass negative values.");

        present |= 1 << inputType;
        if (analog.Length <= inputType)
            analog.Resize(inputType + 1);
        analog[inputType] = analogValue;
    }
}

void IncCommit(SimulationManager@ sim, const IncCommitContext ctx = IncCommitContext())
{
    array<InputCommand> commands;

    const ms time = Core::tInput;
    // Note: just doing all input types for completeness I suppose, but we really only need the first half.
    for (uint i = 0; i < INPUT_TYPE_COUNT; ++i)
    {
        const InputType inputType = InputType(i);
        int state;
        if (!ctx.Get(inputType, state))
            continue;

        Core::SetInput(sim, time, inputType, state);

        InputCommand cmd;
        cmd.Timestamp = time;
        cmd.Type = inputType;
        cmd.State = state;
        commands.Add(cmd);
    }

    Settings::PrintInfo(commands);
    Core::Advance();
}
