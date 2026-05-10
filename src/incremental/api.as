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

    Settings::PrintInfo(commands);
    Core::Advance();
}
