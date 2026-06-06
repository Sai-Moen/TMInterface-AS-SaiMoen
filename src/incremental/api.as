interface IncIMode
{
    bool SingleIteration { get; }
    array<InputType> ExcludedInputTypes { get; }

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
    array<InputType> excludedInputTypes;

    OnDraw@ draw;

    OnBegin@ begin;
    OnIteration@ iteration;
    OnStep@ step;
    OnEnd@ end;
}

bool IncRegisterMode(const string &in modeName, IncIMode@ imode)
{
    IncMode mode;

    mode.singleIteration    = imode.SingleIteration;
    mode.excludedInputTypes = imode.ExcludedInputTypes;

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


void IncTerminate(SimulationManager@ sim)
{
    Core::Finish(sim);
}


ms IncTimeGetAbsolute(SimulationManager@ sim)
{
    return sim.TickTime;
}

ms IncTimeGetRelative(SimulationManager@ sim)
{
    return sim.TickTime - Core::tInput;
}

ms IncTimeAbsoluteFromRelative(ms relativeTime)
{
    return relativeTime + Core::tInput;
}

ms IncTimeRelativeFromAbsolute(ms absoluteTime)
{
    return absoluteTime - Core::tInput;
}


bool IncInputGet(SimulationManager@ sim, InputType type, int &out value = void)
{
    return Core::InputGet(sim, sim.TickTime, type, value);
}

bool IncInputGetAbsolute(SimulationManager@ sim, ms absoluteTime, InputType type, int &out value = void)
{
    return Core::InputGet(sim, absoluteTime, type, value);
}

bool IncInputGetRelative(SimulationManager@ sim, ms relativeTime, InputType type, int &out value = void)
{
    return Core::InputGet(sim, Core::tInput + relativeTime, type, value);
}


void IncInputSet(SimulationManager@ sim, InputType type, int value)
{
    Core::InputSet(sim, sim.TickTime, type, value);
}

void IncInputSetAbsolute(SimulationManager@ sim, ms absoluteTime, InputType type, int value)
{
    Core::InputSet(sim, absoluteTime, type, value);
}

void IncInputSetRelative(SimulationManager@ sim, ms relativeTime, InputType type, int value)
{
    Core::InputSet(sim, Core::tInput + relativeTime, type, value);
}


void IncInputRemove(SimulationManager@ sim, InputType type)
{
    Core::InputRemove(sim, sim.TickTime, type);
}

void IncInputRemoveAbsolute(SimulationManager@ sim, ms absoluteTime, InputType type)
{
    Core::InputRemove(sim, absoluteTime, type);
}

void IncInputRemoveRelative(SimulationManager@ sim, ms relativeTime, InputType type)
{
    Core::InputRemove(sim, Core::tInput + relativeTime, type);
}


void IncRewindRemove(SimulationManager@ sim)
{
    Rewind(sim, Core::inputState, RewindFlags::REMOVE);
    Core::PostInitInputEventsFill(sim.InputEvents);
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

IncCommitState IncStageGet(InputType inputType, int &out analogValue = void)
{
    return Core::StageGet(inputType, analogValue);
}

void IncStageSet(InputType inputType, int analogValue)
{
    Core::StageSet(inputType, analogValue);
}

void IncStageRemove(InputType inputType)
{
    Core::StageRemove(inputType);
}

void IncCommit(SimulationManager@ sim, ms advance = 10)
{
    Core::Commit(sim, advance);
}
