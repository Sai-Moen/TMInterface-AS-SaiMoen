namespace InputSimplifier
{


void Main()
{
    VarsRegister();
    VarsInit();

    IncMode mode;
    mode.singleIteration = true;
    @mode.draw  = Draw;
    @mode.begin = Begin;
    @mode.step  = Step;
    @mode.end   = End;
    IncRegisterMode("Input Simplifier", mode);
}

const string VAR = ::Core::VAR + "input_simplifier_";

const string VAR_CONTEXT_TIMESPAN = VAR + "context_timespan";
const ms DEF_CONTEXT_TIMESPAN = 250;

const string VAR_AIR_MAGNITUDE  = VAR + "air_magnitude";
const string VAR_MINIMIZE_BRAKE = VAR + "minimize_brake";

const string VAR_ORDERED_STRATEGY_INDICES = VAR + "ordered_strategy_indices";

void VarsRegister()
{
    RegisterVariable(VAR_CONTEXT_TIMESPAN, DEF_CONTEXT_TIMESPAN);
    RegisterVariable(VAR_AIR_MAGNITUDE, 0);
    RegisterVariable(VAR_MINIMIZE_BRAKE, false);
    RegisterVariable(VAR_ORDERED_STRATEGY_INDICES, "");
}

const ms CAUSALITY = 20;

ms varContextTimespan;
int varAirMagnitude;
bool varMinimizeBrake;

array<Strategy> varOrderedStrategyIndices(ORDERED_STRATEGY_LEN);

void VarsInit()
{
    varContextTimespan = VarGetTime(VAR_CONTEXT_TIMESPAN);
    if (varContextTimespan < CAUSALITY)
    {
        varContextTimespan = CAUSALITY;
        VarSetTime(VAR_CONTEXT_TIMESPAN, varContextTimespan);
    }

    varAirMagnitude    = VarGetInt(VAR_AIR_MAGNITUDE);
    varMinimizeBrake   = VarGetBool(VAR_MINIMIZE_BRAKE);

    if (!DeserializeStrategyIndicesFromVar())
    {
        for (uint i = 0; i < ORDERED_STRATEGY_LEN; i++)
            varOrderedStrategyIndices[i] = Strategy(i);
    }
}

const string ORDERED_STRATEGY_SEP = ",";

bool DeserializeStrategyIndicesFromVar()
{
    const auto@ const orderedStrategyIndices = VarGetString(VAR_ORDERED_STRATEGY_INDICES).Split(ORDERED_STRATEGY_SEP);
    const uint len = orderedStrategyIndices.Length;
    if (len != ORDERED_STRATEGY_LEN)
        return false;

    for (uint i = 0; i < len; i++)
    {
        uint byteCount;
        const uint64 parsed = Text::ParseUInt(orderedStrategyIndices[i], 10, byteCount);
        if (byteCount == 0 || parsed >= len)
            return false;

        varOrderedStrategyIndices[i] = Strategy(parsed);
    }
    return true;
}

void Draw()
{
    varContextTimespan = UI::InputTime("Context Timespan", varContextTimespan, 10);
    if (varContextTimespan < CAUSALITY)
        varContextTimespan = CAUSALITY;
    VarSetTime(VAR_CONTEXT_TIMESPAN, varContextTimespan);
    TooltipOnHover(
        "Lower timespan is faster, but may desync in an unrecoverable way (default " + DEF_CONTEXT_TIMESPAN + "ms).");

    varAirMagnitude = UI::InputInt("Air Magnitude", varAirMagnitude);
    varAirMagnitude = ClampSteer(varAirMagnitude);
    VarSetInt(VAR_AIR_MAGNITUDE, varAirMagnitude);
    TooltipOnHover(
        "This is the magnitude used by steering inputs in the air, where only input direction matters.\n"
        "Setting this to 0 will skip the air input strategy altogether.");

    varMinimizeBrake = UI::CheckboxVar("Minimize Brake", VAR_MINIMIZE_BRAKE);
    TooltipOnHover(
        "If this is enabled, the amount of time spent braking will be made as small as possible.\n"
        "The trade-off is that this may introduce more brake inputs.");

    UI::Separator();

    UI::TextWrapped("Strategy Order:");
    bool changed = false;
    for (uint i = 0; i < ORDERED_STRATEGY_LEN; ++i)
    {
        const Strategy strategy = varOrderedStrategyIndices[i];

        const bool pressed = UI::Button("Move Down##" + i);
        UI::SameLine();
        switch (strategy)
        {
        case Strategy::SIGN_MAGNITUDE:
            if (varAirMagnitude == 0)
            {
                UI::TextDimmed(ORDERED_STRATEGY_NAMES[strategy]);
                break;
            }
        // fallthrough
        default:
            UI::TextWrapped(ORDERED_STRATEGY_NAMES[strategy]);
        break;
        }

        if (!pressed)
            continue;

        changed = true;
        const uint nextIndex = i + 1;
        if (nextIndex < ORDERED_STRATEGY_LEN)
        {
            varOrderedStrategyIndices[i] = varOrderedStrategyIndices[nextIndex];
            varOrderedStrategyIndices[nextIndex] = strategy;
        }
    }

    if (changed)
    {
        array<string> orderedStrategyIndices(ORDERED_STRATEGY_LEN);
        for (uint i = 0; i < ORDERED_STRATEGY_LEN; i++)
            orderedStrategyIndices[i] = Text::FormatUInt(varOrderedStrategyIndices[i]);
        SetVariable(VAR_ORDERED_STRATEGY_INDICES, Text::Join(orderedStrategyIndices, ORDERED_STRATEGY_SEP));
    }
}

class Context
{
    bool initialized;

    vec3 position;
    mat3 rotation;
    vec3 linearSpeed;
    vec3 angularSpeed;

    void Init(const TM::HmsStateDyna@ const dyna)
    {
        if (initialized)
        {
            Assert(HasEquivalentState(dyna));
            return;
        }
        initialized = true;

        position     = dyna.Location.Position;
        rotation     = dyna.Location.Rotation;
        linearSpeed  = dyna.LinearSpeed;
        angularSpeed = dyna.AngularSpeed;
    }

    bool HasEquivalentState(const TM::HmsStateDyna@ const dyna) const
    {
        Assert(initialized);
        return
            EqualsVec3(position,     dyna.Location.Position) &&
            EqualsMat3(rotation,     dyna.Location.Rotation) &&
            EqualsVec3(linearSpeed,  dyna.LinearSpeed)       &&
            EqualsVec3(angularSpeed, dyna.AngularSpeed)      ;
    }
}

bool EqualsMat3(const mat3 &in m1, const mat3 &in m2)
{
    return
        EqualsVec3(m1.x, m2.x) &&
        EqualsVec3(m1.y, m2.y) &&
        EqualsVec3(m1.z, m2.z) ;
}

bool EqualsVec3(const vec3 &in v1, const vec3 &in v2)
{
    return
        v1.x == v2.x &&
        v1.y == v2.y &&
        v1.z == v2.z ;
}

array<Context> contexts;
uint contextIndex;

enum Strategy
{
    // Ordered
    TURNING_RATE,
    SIGN_MAGNITUDE,
    REMOVAL,

    // Unordered
    MINIMIZE_BRAKE,

    COUNT
}

// MINIMIZE_BRAKE is not an ordered strategy, so this is an exclusive upper bound (also keep in sync with the enum).
const uint ORDERED_STRATEGY_LEN = Strategy::MINIMIZE_BRAKE;

const array<string> ORDERED_STRATEGY_NAMES =
{
    "Turning Rate",
    "Sign-Magnitude",
    "Removal"
};

funcdef void OnStep(SimulationManager@);

const array<OnStep@> ORDERED_STRATEGY_CALLBACKS =
{
    StepTurningRate,
    StepAir,
    StepRemoval
};

array<OnStep@> steps;
uint stepIndex;

void Begin(SimulationManager@)
{
    VarsInit();

    contexts.Resize(varContextTimespan / 10 - 1);
    contextIndex = 0;

    steps.Add(StepScan);
    if (varMinimizeBrake)
        steps.Add(StepMinimizeBrake);

    const uint len = varOrderedStrategyIndices.Length;
    for (uint i = 0; i < len; i++)
    {
        const Strategy strategy = varOrderedStrategyIndices[i];
        switch (strategy)
        {
        case Strategy::SIGN_MAGNITUDE:
            if (varAirMagnitude == 0)
                continue;
        break;
        }

        steps.Add(ORDERED_STRATEGY_CALLBACKS[strategy]);
    }
    stepIndex = 0;
}

void Step(SimulationManager@ sim)
{
    steps[stepIndex](sim);
}

void End(SimulationManager@ sim)
{
    contexts.Clear();
    steps.Clear();

    // Variables that directly or indirectly cause uninitialized variables to be used incorrectly.
    fillSteer = false;
    fillBrake = false;
}

int brake0;
int steer0;

int   brake1;
int   steer1;
float turningRate1;

float turningRate2;

bool minimizeBrake;
bool fillBrake;
bool preserveBrake;

bool fillSteer;
bool preserveSteer;
int  preservedSteer;

void StepScan(SimulationManager@ sim)
{
    const auto@ const svc = sim.SceneVehicleCar;

    const ms time = IncTimeGetRelative(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        brake0 = int(svc.InputBrake);
        steer0 = ToSteer(svc.InputSteer);

        preserveBrake = fillBrake && brake0 == 0;
        if (preserveBrake)
        {
            Assert(minimizeBrake);
            IncInputSet(sim, InputType::Down, 1);
        }

        preserveSteer = fillSteer && preservedSteer != steer0;
        if (preserveSteer)
            IncInputSet(sim, InputType::Steer, preservedSteer);

        return;
    case 1:
        brake1  = int(svc.InputBrake);
        steer1  = ToSteer(svc.InputSteer);
        turningRate1 = svc.TurningRate;

        minimizeBrake = varMinimizeBrake && brake1 == 1;
        if (minimizeBrake)
        {
            fillBrake = !IncInputGet(sim, InputType::Down);
            if (fillBrake)
                IncInputSet(sim, InputType::Down, 1);
        }
        else
        {
            fillBrake = false;
        }

        fillSteer = !IncInputGet(sim, InputType::Steer);
        if (fillSteer)
        {
            preservedSteer = steer1;
            IncInputSet(sim, InputType::Steer, preservedSteer);
        }

        return;
    case 2:
        turningRate2 = svc.TurningRate;
    break;
    }

    RelativeTickToContext(tick).Init(sim.Dyna.RefStateCurrent);
    if (time == varContextTimespan)
        NextStep(sim);
}

void StepMinimizeBrake(SimulationManager@ sim)
{
    if (!minimizeBrake)
    {
        NextStep(sim);
        return;
    }

    const ms time = IncTimeGetRelative(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        IncInputSet(sim, InputType::Down, 0);
    // fallthrough
    case 1:
        return;
    }

    if (Desynced(sim, tick))
    {
        IncInputSetRelative(sim, 0, InputType::Down, 1);
        NextStep(sim);
    }
    else if (time == varContextTimespan)
    {
        IncStageSet(InputType::Down, 0);
        NextStep(sim);
    }
}

int steer;

void StepTurningRate(SimulationManager@ sim)
{
    const ms time = IncTimeGetRelative(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        steer = RoundAway(turningRate2 * STEER_FULL, turningRate2 - turningRate1);
        IncInputSet(sim, InputType::Steer, steer);
    // fallthrough
    case 1:
        return;
    }

    if (Desynced(sim, tick))
    {
        NextStep(sim);
    }
    else if (time == varContextTimespan)
    {
        IncStageSet(InputType::Steer, steer);
        Commit(sim);
    }
}

void StepAir(SimulationManager@ sim)
{
    const ms time = IncTimeGetRelative(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        steer = GetSign(steer1) * varAirMagnitude;
        IncInputSet(sim, InputType::Steer, steer);
    // fallthrough
    case 1:
        return;
    }

    if (Desynced(sim, tick))
    {
        NextStep(sim);
    }
    else if (time == varContextTimespan)
    {
        IncStageSet(InputType::Steer, steer);
        Commit(sim);
    }
}

void StepRemoval(SimulationManager@ sim)
{
    const ms time = IncTimeGetRelative(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        IncInputRemove(sim, InputType::Steer);
    // fallthrough
    case 1:
        return;
    }

    if (Desynced(sim, tick))
    {
        NextStep(sim);
    }
    else if (time == varContextTimespan)
    {
        IncStageRemove(InputType::Steer);
        Commit(sim);
    }
}

bool Desynced(SimulationManager@ sim, const uint relativeTick)
{
    const Context@ const context = RelativeTickToContext(relativeTick);
    return !context.HasEquivalentState(sim.Dyna.RefStateCurrent);
}

Context@ RelativeTickToContext(const uint relativeTick)
{
    Assert(relativeTick >= 2);
    const uint offset = relativeTick - 2;
    const uint len = contexts.Length;
    Assert(offset < len);
    return contexts[(contextIndex + offset) % len];
}

void NextStep(SimulationManager@ sim)
{
    const uint len = steps.Length;
    Assert(stepIndex < len);
    if (++stepIndex == len)
    {
        print("[Input Simplifier] Desynchronized, restoring old inputs...", Severity::Warning);
        Commit(sim);
        return;
    }

    IncRewindPreserve(sim);
    Step(sim);
}

void Commit(SimulationManager@ sim)
{
    contexts[contextIndex++].initialized = false;
    contextIndex %= contexts.Length;
    stepIndex = 0;

    int brake;
    switch (IncStageGet(InputType::Down, brake))
    {
    case IncCommitState::NONE:
        if (preserveBrake)
            IncStageSet(InputType::Down, 1);
    break;
    case IncCommitState::SET:
        Assert(brake == 0);
        if (brake0 == 0)
            IncStageRemove(InputType::Down);
    break;
    case IncCommitState::REMOVE:
        // Unreachable.
    // fallthrough
    default:
        print("[Input Simplifier] Unexpected state for brake!", Severity::Error);
        IncTerminate(sim);
        return;
    }

    int steer;
    switch (IncStageGet(InputType::Steer, steer))
    {
    case IncCommitState::NONE:
        if (preserveSteer)
            IncStageSet(InputType::Steer, preservedSteer);
    break;
    case IncCommitState::SET:
        if (steer == steer0)
            IncStageRemove(InputType::Steer);
    break;
    case IncCommitState::REMOVE:
        // Possible; no-op.
    break;
    default:
        print("[Input Simplifier] Unexpected state for steer!", Severity::Error);
        IncTerminate(sim);
        return;
    }

    IncCommit(sim);
}


} // namespace InputSimplifier
