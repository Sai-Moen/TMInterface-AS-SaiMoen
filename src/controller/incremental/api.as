// API

typedef int ms;

interface IncMode
{
    bool SupportsUnlockedTimerange { get; }

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

ms IncGetAbsoluteTime(const ms relativeTickTime)
{
    return Eval::tInput + relativeTickTime;
}

void IncSetInput(SimulationManager@ simManager, const InputType type, const int value)
{
    Eval::SetInput(simManager, 0, type, value);
}

void IncSetInput(SimulationManager@ simManager, const ms relativeTime, const InputType type, const int value)
{
    Eval::SetInput(simManager, utils::MsToTick(relativeTime), type, value);
}

bool IncHasInputs(
    SimulationManager@ simManager,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    return IncHasInputs(simManager, 0, type, value);
}

bool IncHasInputs(
    SimulationManager@ simManager, const ms relativeTime,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    return !simManager.InputEvents.Find(IncGetAbsoluteTime(relativeTime), type, value).IsEmpty();
}

void IncRemoveInputs(
    SimulationManager@ simManager,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    IncRemoveInputs(simManager, 0, type, value);
}

void IncRemoveInputs(
    SimulationManager@ simManager, const ms relativeTime,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    auto@ const buffer = simManager.InputEvents;
    const uint len = buffer.Length;
    utils::BufferRemoveIndices(buffer, buffer.Find(IncGetAbsoluteTime(relativeTime), type, value));

    if (buffer.Length < len)
        Eval::ClearInputCaches();
}

void IncRemoveSteeringAhead(SimulationManager@ simManager)
{
    auto@ const buffer = simManager.InputEvents;
    const uint len = buffer.Length;
    utils::BufferRemoveInTimerange(
        buffer, Eval::tInput, Eval::tCleanup,
        { InputType::Left, InputType::Right, InputType::Steer });

    if (buffer.Length < len)
        Eval::ClearInputCaches();
}

SimulationState@ IncGetTrailingState()
{
    return Eval::trailingState;
}

void IncRewind(SimulationManager@ simManager)
{
    simManager.RewindToState(Eval::trailingState);
}

class IncCommitContext
{
    int down  = -1;
    int up    = -1;
    int steer = Math::INT_MIN;
}

const IncCommitContext ctxNeutral;

void IncCommit(SimulationManager@ simManager, const IncCommitContext ctx = IncCommitContext())
{
    const ms time = Eval::tInput;
    array<InputCommand> commands;

    const int down = ctx.down;
    if (down != ctxNeutral.down)
    {
        const InputType type = InputType::Down;
        IncSetInput(simManager, type, down);
        commands.Add(utils::MakeInputCommand(time, type, down));
    }

    const int up = ctx.up;
    if (up != ctxNeutral.up)
    {
        const InputType type = InputType::Up;
        IncSetInput(simManager, type, up);
        commands.Add(utils::MakeInputCommand(time, type, up));
    }

    const int steer = ctx.steer;
    if (steer != ctxNeutral.steer)
    {
        const InputType type = InputType::Steer;
        IncSetInput(simManager, type, steer);
        commands.Add(utils::MakeInputCommand(time, type, steer));
    }

    Settings::PrintInfo(commands);
    Eval::Advance();
}
