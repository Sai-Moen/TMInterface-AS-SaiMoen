interface IncIMode
{
    bool SingleIteration { get; }
    array<InputType> PreservationExclusions { get; }

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
    array<InputType> preservationExclusions;

    OnDraw@ draw;

    OnBegin@ begin;
    OnIteration@ iteration;
    OnStep@ step;
    OnEnd@ end;
}

bool IncRegisterMode(const string &in modeName, IncIMode@ imode)
{
    IncMode mode;

    mode.singleIteration        = imode.SingleIteration;
    mode.preservationExclusions = imode.PreservationExclusions;

    @mode.draw = OnDraw(imode.Draw);

    @mode.begin     = OnBegin(imode.Begin);
    @mode.iteration = OnIteration(imode.Iteration);
    @mode.step      = OnStep(imode.Step);
    @mode.end       = OnEnd(imode.End);

    return IncRegisterMode(modeName, mode);
}

bool IncRegisterMode(const string &in modeName, IncMode@ mode)
{
    if (Core::modeNames.Find(modeName) != -1)
        return false;

    Core::modeNames.Add(modeName);

    if (mode.draw is null) @mode.draw = function() {};

    if (mode.begin is null)     @mode.begin     = function(sim) {};
    if (mode.iteration is null) @mode.iteration = function(sim) {};
    if (mode.step is null)      @mode.step      = function(sim) {};
    if (mode.end is null)       @mode.end       = function(sim) {};

    Core::modes.Add(mode);
    return true;
}

ms IncGetRelativeTime(SimulationManager@ sim)
{
    return Core::GetRelativeTime(sim.TickTime);
}

ms IncGetRelativeTime(ms absoluteTime)
{
    return Core::GetRelativeTime(absoluteTime);
}

ms IncGetAbsoluteTime(ms relativeTime)
{
    return Core::GetAbsoluteTime(relativeTime);
}

bool IncInputGet(SimulationManager@ sim, InputType type, int &out value = void)
{
    return Core::InputGet(sim, Core::tInput, type, value);
}

bool IncInputGet(SimulationManager@ sim, ms relativeTime, InputType type, int &out value = void)
{
    return Core::InputGet(sim, Core::GetAbsoluteTime(relativeTime), type, value);
}

void IncInputSet(SimulationManager@ sim, InputType type, int value)
{
    Core::InputSet(sim, Core::tInput, type, value);
}

void IncInputSet(SimulationManager@ sim, ms relativeTime, InputType type, int value)
{
    Core::InputSet(sim, Core::GetAbsoluteTime(relativeTime), type, value);
}

void IncInputRemove(SimulationManager@ sim, InputType type)
{
    Core::InputRemove(sim, Core::tInput, type);
}

void IncInputRemove(SimulationManager@ sim, ms relativeTime, InputType type)
{
    Core::InputRemove(sim, Core::GetAbsoluteTime(relativeTime), type);
}

SimulationState@ IncGetInputState()
{
    return Core::inputState;
}

void IncRewindRemove(SimulationManager@ sim)
{
    Rewind(sim, Core::inputState, RewindFlags::REMOVE);
    Core::PostInitInputEventsCopyToIEB(sim.InputEvents);
}

void IncRewindPreserve(SimulationManager@ sim)
{
    Rewind(sim, Core::inputState, RewindFlags::PRESERVE);
}

enum IncCommitState
{
    NONE,   // No particular change is requested (default).
    SET,    // Sets input type to analog value at input time (adds input event if necessary).
    REMOVE, // Removes (all) input event(s) with the given type at input time.
}

class IncCommitContext
{
    protected array<IncCommitState> states;
    protected array<int> analog;

    // 'states' is monotonically longer than 'analog'.
    uint Length { get const { return states.Length; } }

    IncCommitState Get(InputType inputType, int &out analogValue = void) const
    {
        analogValue = 0;
        if (inputType == InputType::None)
            return IncCommitState::NONE;

        const uint index = inputType;
        const IncCommitState state = index < states.Length ? states[index] : IncCommitState::NONE;
        if (state == IncCommitState::SET)
            analogValue = analog[index];
        return state;
    }

    void Set(InputType inputType, const int analogValue)
    {
        if (inputType == InputType::None)
            return;

        AssertLog(inputType >= 0, "Tried to allocate a few GiB, do not pass negative values for inputType.");

        const uint index = inputType;
        if (index >= analog.Length)
        {
            analog.Resize(index + 1);
            if (index >= states.Length)
                states.Resize(index + 1);
        }

        states[index] = IncCommitState::SET;
        analog[index] = analogValue;
    }

    void Remove(InputType inputType)
    {
        if (inputType == InputType::None)
            return;

        AssertLog(inputType >= 0, "Tried to allocate a few GiB, do not pass negative values for inputType.");

        const uint index = inputType;
        if (index >= states.Length)
            states.Resize(index + 1);

        states[index] = IncCommitState::REMOVE;
    }

    void Clear()
    {
        states.Clear();
        analog.Clear();
    }
}

void IncCommit(SimulationManager@ sim, const IncCommitContext@ ctx = IncCommitContext())
{
    const ms time = Core::tInput;
    Core::tInput += 10;

    Rewind(sim, Core::inputState, RewindFlags::REMOVE);
    Core::PostInitInputEventsAdvance(sim.InputEvents);

    string s;
    s += time;
    s += ":\n";

    if (VarGetBool(Core::VAR_SHOW_INFO))
    {
        // NOTE: since we already did a rewind to inputState on this tick, we can access SimulationManager directly for stuff.
        const float mps = sim.Dyna.RefStateCurrent.LinearSpeed.Length();

        s += "Speed (km/h): ";
        s += FormatPrecise(mps * 3.6);
        s += "\n";
    }

    const uint len = ctx.Length;
    for (uint i = 0; i < len; ++i)
    {
        const InputType type = InputType(i);
        int value;
        const IncCommitState state = ctx.Get(type, value);
        if (state == IncCommitState::NONE)
            continue;

        switch (state)
        {
        case IncCommitState::NONE:
            // Do nothing.
        continue;
        case IncCommitState::SET:
            Core::InputSet(sim, time, type, value);
            s += "+ ";
        break;
        case IncCommitState::REMOVE:
            Core::InputRemove(sim, time, type);
            s += "- ";
        break;
        default:
            Unreachable();
        break;
        }

        InputCommand cmd;
        cmd.Timestamp = time;
        cmd.Type = type;
        cmd.State = value;
        s += cmd.ToString();
        s += "\n";
    }

    print(s);
}
