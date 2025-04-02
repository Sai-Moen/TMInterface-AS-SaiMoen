// API

interface IncMode
{
    bool SupportsUnlockedTimerange { get; }

    void RenderSettings();

    void OnBegin(SimulationManager@);
    void OnStep(SimulationManager@);
    void OnEnd(SimulationManager@);
}

bool IncRegisterMode(const string &in modeName, IncMode@ imode)
{
    if (Eval::modeNames.Find(modeName) != -1)
        return false;

    Eval::modeNames.Add(modeName);
    Eval::modes.Add(imode);
    return true;
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
    Eval::SetInput(simManager, Eval::tInput, type, value);
}

void IncSetInput(SimulationManager@ simManager, const ms relativeTime, const InputType type, const int value)
{
    Eval::SetInput(simManager, IncGetAbsoluteTime(relativeTime), type, value);
}

bool IncHasInputs(
    SimulationManager@ simManager,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    return Eval::HasInputs(simManager, Eval::tInput, type, value);
}

bool IncHasInputs(
    SimulationManager@ simManager,
    const ms relativeTime, const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    return Eval::HasInputs(simManager, IncGetAbsoluteTime(relativeTime), type, value);
}

void IncRemoveInputs(
    SimulationManager@ simManager,
    const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    Eval::RemoveInputs(simManager, Eval::tInput, type, value);
}

void IncRemoveInputs(
    SimulationManager@ simManager,
    const ms relativeTime, const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    Eval::RemoveInputs(simManager, IncGetAbsoluteTime(relativeTime), type, value);
}

void IncRemoveSteeringAhead(SimulationManager@ simManager)
{
    Eval::RemoveSteeringAhead(simManager);
}

SimulationState@ IncGetTrailingState()
{
    return Eval::trailingState;
}

void IncRewind(SimulationManager@ simManager)
{
    Eval::RewindToTrailingState(simManager);
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
        commands.Add(Eval::MakeInputCommand(time, type, down));
    }

    const int up = ctx.up;
    if (up != ctxNeutral.up)
    {
        const InputType type = InputType::Up;
        IncSetInput(simManager, type, up);
        commands.Add(Eval::MakeInputCommand(time, type, up));
    }

    const int steer = ctx.steer;
    if (steer != ctxNeutral.steer)
    {
        const InputType type = InputType::Steer;
        IncSetInput(simManager, type, steer);
        commands.Add(Eval::MakeInputCommand(time, type, steer));
    }

    Settings::PrintInfo(commands);
    Eval::Advance();
}
