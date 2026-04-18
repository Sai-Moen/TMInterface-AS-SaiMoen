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
    Core::RewindToTrailingState(sim);
}

class IncCommitContext
{
    int down  = -1;
    int up    = -1;
    int steer = Math::INT_MIN;
}

const IncCommitContext ctxNeutral;

void IncCommit(SimulationManager@ sim, const IncCommitContext ctx = IncCommitContext())
{
    const ms time = Core::tInput;
    array<InputCommand> commands;

    const int down = ctx.down;
    if (down != ctxNeutral.down)
    {
        const InputType type = InputType::Down;
        IncSetInput(sim, type, down);
        commands.Add(Core::MakeInputCommand(time, type, down));
    }

    const int up = ctx.up;
    if (up != ctxNeutral.up)
    {
        const InputType type = InputType::Up;
        IncSetInput(sim, type, up);
        commands.Add(Core::MakeInputCommand(time, type, up));
    }

    const int steer = ctx.steer;
    if (steer != ctxNeutral.steer)
    {
        const InputType type = InputType::Steer;
        IncSetInput(sim, type, steer);
        commands.Add(Core::MakeInputCommand(time, type, steer));
    }

    Settings::PrintInfo(commands);
    Core::Advance();
}
