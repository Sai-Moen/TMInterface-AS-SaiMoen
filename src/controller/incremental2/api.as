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

void IncSetInput(SimulationManager@ simManager, const InputType type, const int value)
{
    Eval::SetInput(simManager, 0, type, value);
}

void IncSetInput(SimulationManager@ simManager, const ms relativeTime, const InputType type, const int value)
{
    Eval::SetInput(simManager, utils::MsToTick(relativeTime), type, value);
}

void IncRemoveSteering(SimulationManager@ simManager, const ms timeFrom, const ms timeTo)
{
    auto@ const buffer = simManager.InputEvents;
    const uint len = buffer.Length;
    utils::BufferRemoveInTimerange(
        buffer, timeFrom, timeTo,
        { InputType::Left, InputType::Right, InputType::Steer });

    if (buffer.Length < len)
        Eval::ClearInputCaches(); // should be faster to just invalidate everything
}

void IncRewind(SimulationManager@ simManager)
{
    simManager.RewindToState(Eval::trailingState);
}

const int NO_DOWN_CHANGE = -1;
const int NO_UP_CHANGE = -1;
const int NO_STEER_CHANGE = Math::INT_MIN;

class IncCommitContext
{
    int down = NO_DOWN_CHANGE;
    int up = NO_UP_CHANGE;
    int steer = NO_STEER_CHANGE;
}

void IncCommit(SimulationManager@ simManager, const IncCommitContext ctx)
{
    const ms time = Eval::tInput;
    array<InputCommand> commands;
    auto@ const buffer = simManager.InputEvents;

    const int down = ctx.down;
    if (down != NO_DOWN_CHANGE)
    {
        const InputType type = InputType::Down;
        Eval::SetInput(simManager, time, type, down);
        commands.Add(utils::MakeInputCommand(time, type, down));
    }

    const int up = ctx.up;
    if (up != NO_UP_CHANGE)
    {
        const InputType type = InputType::Up;
        Eval::SetInput(simManager, time, type, up);
        commands.Add(utils::MakeInputCommand(time, type, up));
    }

    const int steer = ctx.steer;
    if (steer != NO_STEER_CHANGE)
    {
        const InputType type = InputType::Steer;
        Eval::SetInput(simManager, time, type, steer);
        commands.Add(utils::MakeInputCommand(time, type, steer));
    }

    Settings::PrintInfo(commands);
    Eval::Advance();
}
