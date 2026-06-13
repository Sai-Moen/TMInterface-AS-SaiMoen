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

funcdef void IncOnDraw();

funcdef void IncOnBegin(SimulationManager@);
funcdef void IncOnIteration(SimulationManager@);
funcdef void IncOnStep(SimulationManager@);
funcdef void IncOnEnd(SimulationManager@);

class IncMode
{
    bool singleIteration;
    array<InputType> excludedInputTypes;

    IncOnDraw@ draw;

    IncOnBegin@ begin;
    IncOnIteration@ iteration;
    IncOnStep@ step;
    IncOnEnd@ end;
}

bool IncModeRegister(const string &in name, IncIMode@ imode)
{
    if (imode is null)
        return false;

    return Core::ModeRegister(name, imode);
}

bool IncModeRegister(const string &in name, const IncMode &in mode)
{
    return Core::ModeRegister(name, mode);
}


ms IncTimeGetAbsolute(SimulationManager@ sim)
{
    return sim.TickTime;
}

ms IncTimeGetRelative(SimulationManager@ sim)
{
    return sim.TickTime - Core::inputTime;
}

ms IncTimeAbsoluteFromRelative(ms relativeTime)
{
    return relativeTime + Core::inputTime;
}

ms IncTimeRelativeFromAbsolute(ms absoluteTime)
{
    return absoluteTime - Core::inputTime;
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
    return Core::InputGet(sim, Core::inputTime + relativeTime, type, value);
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
    Core::InputSet(sim, Core::inputTime + relativeTime, type, value);
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
    Core::InputRemove(sim, Core::inputTime + relativeTime, type);
}


enum IncStageState
{
    NONE,   // No particular change is requested (default).
    SET,    // Sets input type to analog value at input time (adds input event if necessary).
    REMOVE, // Removes (all) input event(s) with the given type at input time.
}

IncStageState IncStageGet(InputType inputType, int &out analogValue = void)
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


ms IncForwardCheck(SimulationManager@ sim, ms forward = 10)
{
    return Core::ForwardCheck(sim, forward);
}

void IncForward(SimulationManager@ sim, ms forward = 10)
{
    Core::Forward(sim, forward);
}

ms IncBackwardCheck(SimulationManager@ sim, ms backward = 10)
{
    return Core::BackwardCheck(sim, backward);
}

void IncBackward(SimulationManager@ sim, ms backward = 10, ms cacheHint = 0)
{
    Core::Backward(sim, backward, cacheHint);
}


void IncRewindPreserve(SimulationManager@ sim)
{
    Rewind(sim, Core::inputState, RewindFlags::PRESERVE);
}

void IncRewindRemove(SimulationManager@ sim)
{
    Rewind(sim, Core::inputState, RewindFlags::REMOVE);
    Core::PostInitInputEventsFill(sim.InputEvents);
}

void IncRevert(SimulationManager@ sim)
{
    Rewind(sim, Core::baseState, RewindFlags::REMOVE);
    Core::Iteration(sim);
}

void IncTerminate(SimulationManager@ sim)
{
    Core::Finish(sim);
}
