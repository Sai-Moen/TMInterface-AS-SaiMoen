namespace InputSimplifier
{


void Main()
{
    Register();

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
const ms DEF_CTX_TIMESPAN = 250;
const string DEF_CTX_TIMESPAN_TEXT = "(default " + DEF_CTX_TIMESPAN + "ms)";

const string VAR_ORDERED_STRATEGY_INDICES = VAR + "ordered_strategy_indices";
array<Strategy> varOrderedStrategyIndices(ORDERED_STRATEGY_LEN);

const string VAR_AIR_MAGNITUDE = VAR + "air_magnitude";
const string VAR_MINIMIZE_BRAKE = VAR + "minimize_brake";

void Register()
{
    RegisterVariable(VAR_CONTEXT_TIMESPAN, DEF_CTX_TIMESPAN);
    RegisterVariable(VAR_ORDERED_STRATEGY_INDICES, "");
    RegisterVariable(VAR_AIR_MAGNITUDE, 0);
    RegisterVariable(VAR_MINIMIZE_BRAKE, false);

    if (!DeserializeStrategyIndicesFromVar())
    {
        for (uint i = 0; i < ORDERED_STRATEGY_LEN; i++)
            varOrderedStrategyIndices[i] = Strategy(i);
    }
}

const string STRATEGY_SEP = ",";

bool DeserializeStrategyIndicesFromVar()
{
    const auto@ const orderedStrategyIndices = GetVariableString(VAR_ORDERED_STRATEGY_INDICES).Split(STRATEGY_SEP);
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
    UI::InputTimeVar("Context Timespan", VAR_CONTEXT_TIMESPAN, 10);
    TooltipOnHover("Lower timespan is faster, but may desync in an unrecoverable way " + DEF_CTX_TIMESPAN_TEXT + ".");

    int airMagnitude = UI::InputIntVar("Air Magnitude", VAR_AIR_MAGNITUDE);
    airMagnitude = ClampSteer(airMagnitude);
    VarSetInt(VAR_AIR_MAGNITUDE, airMagnitude);
    TooltipOnHover(
        "This is the magnitude used by steering inputs in the air, where only input direction matters.\n"
        "Setting this to 0 will skip the air input strategy altogether.");

    UI::CheckboxVar("Minimize Brake", VAR_MINIMIZE_BRAKE);
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
            if (airMagnitude == 0)
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
        SetVariable(VAR_ORDERED_STRATEGY_INDICES, Text::Join(orderedStrategyIndices, STRATEGY_SEP));
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
        const iso4 location = dyna.Location;
        position = location.Position;
        rotation = location.Rotation;
        linearSpeed = dyna.LinearSpeed;
        angularSpeed = dyna.AngularSpeed;

        initialized = true;
    }

    bool HasEquivalentState(const TM::HmsStateDyna@ const other) const
    {
        Assert(initialized);

        const iso4 location = other.Location;
        return
            EqualsVec3(position, location.Position) &&
            EqualsMat3(rotation, location.Rotation) &&
            EqualsVec3(linearSpeed, other.LinearSpeed) &&
            EqualsVec3(angularSpeed, other.AngularSpeed);
    }
}

bool EqualsMat3(const mat3 &in m1, const mat3 &in m2)
{
    return
        EqualsVec3(m1.x, m2.x) &&
        EqualsVec3(m1.y, m2.y) &&
        EqualsVec3(m1.z, m2.z);
}

bool EqualsVec3(const vec3 &in v1, const vec3 &in v2)
{
    return
        v1.x == v2.x &&
        v1.y == v2.y &&
        v1.z == v2.z;
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

ms contextTimespan;

array<OnStep@> steps;
uint stepIndex;

int varAirMagnitude;
bool varMinimizeBrake;

void Begin(SimulationManager@)
{
    contextTimespan = VarGetMs(VAR_CONTEXT_TIMESPAN);
    if (contextTimespan < 20)
        contextTimespan = 20;
    contexts.Resize(contextTimespan / 10 - 1);
    contextIndex = 0;

    varAirMagnitude = VarGetInt(VAR_AIR_MAGNITUDE);

    steps.Add(StepScan);

    varMinimizeBrake = VarGetBool(VAR_MINIMIZE_BRAKE);
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

int prevInputBrake;
int prevInputSteer;

int   oldInputBrake;
int   oldInputSteer;
float oldTurningRate;

float nextTurningRate;

IncCommitContext ctx;

bool minimizeBrake;
bool fillBrake;
bool preserveBrake;

bool fillSteer;
bool preserveSteer;
int  preservedInputSteer;

void StepScan(SimulationManager@ sim)
{
    const auto@ const svc = sim.SceneVehicleCar;

    const ms time = IncGetRelativeTime(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        prevInputBrake = int(svc.InputBrake);
        prevInputSteer = ToSteer(svc.InputSteer);

        preserveBrake = fillBrake && prevInputBrake == 0;
        if (preserveBrake)
        {
            Assert(minimizeBrake);
            IncInputSet(sim, InputType::Down, 1);
        }

        // If the old 'oldInputSteer' is not equal to the new 'prevInputSteer',
        // then we managed to change the steering input in the previous commit.
        // However, if we filled the steer while doing the previous commit,
        // we must use that steer on this commit, unless we find a better one.
        preservedInputSteer = oldInputSteer;
        preserveSteer = fillSteer && preservedInputSteer != prevInputSteer;
        if (preserveSteer)
            IncInputSet(sim, InputType::Steer, preservedInputSteer);
    return;
    case 1:
        oldInputBrake  = int(svc.InputBrake);
        oldInputSteer  = ToSteer(svc.InputSteer);
        oldTurningRate = svc.TurningRate;

        minimizeBrake = varMinimizeBrake && oldInputBrake == 1;
        if (minimizeBrake)
        {
            fillBrake = !IncInputGet(sim, 10, InputType::Down);
            if (fillBrake)
                IncInputSet(sim, 10, InputType::Down, 1);
        }
        else
        {
            fillBrake = false;
        }

        // If this tick does not have an input,
        // we must fill it to avoid overriding the intended inputSteer (that tick 0 would otherwise accidentally change).
        fillSteer = !IncInputGet(sim, 10, InputType::Steer);
        if (fillSteer)
            IncInputSet(sim, 10, InputType::Steer, oldInputSteer);
    return;
    case 2:
        nextTurningRate = svc.TurningRate;
    break;
    }

    const auto@ const dyna = sim.Dyna.RefStateCurrent;

    Context@ const context = RelativeTickToContext(tick);
    if (!context.initialized)
        context.Init(dyna);
    else
        AssertPrint(context.HasEquivalentState(dyna), "[Input Simplifier] Ring buffer corruption!");

    if (time == contextTimespan)
        NextStep(sim);
}

void StepMinimizeBrake(SimulationManager@ sim)
{
    if (!minimizeBrake)
    {
        NextStep(sim);
        return;
    }

    const ms time = IncGetRelativeTime(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        IncInputSet(sim, InputType::Down, 0);
    return;
    case 1:
    return;
    }

    if (Desynced(sim, tick))
    {
        IncInputSet(sim, InputType::Down, 1);
        NextStep(sim);
    }
    else if (time == contextTimespan)
    {
        ctx.Set(InputType::Down, 0);
        NextStep(sim);
    }
}

int steer;

void StepTurningRate(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        steer = RoundAway(nextTurningRate * STEER_FULL, nextTurningRate - oldTurningRate);
        IncInputSet(sim, InputType::Steer, steer);
    return;
    case 1:
    return;
    }

    if (Desynced(sim, tick))
        NextStep(sim);
    else if (time == contextTimespan)
        AdvanceUnfill(sim);
}

void StepAir(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        steer = Sign(oldInputSteer) * varAirMagnitude;
        IncInputSet(sim, InputType::Steer, steer);
    return;
    case 1:
    return;
    }

    if (Desynced(sim, tick))
        NextStep(sim);
    else if (time == contextTimespan)
        AdvanceUnfill(sim);
}

void StepRemoval(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        IncInputRemove(sim, InputType::Steer);
    return;
    case 1:
    return;
    }

    if (Desynced(sim, tick))
    {
        NextStep(sim);
    }
    else if (time == contextTimespan)
    {
        ctx.Remove(InputType::Steer);
        Commit(sim);
    }
}

bool Desynced(SimulationManager@ sim, const uint relativeTick)
{
    Context@ const context = RelativeTickToContext(relativeTick);
    return !context.HasEquivalentState(sim.Dyna.RefStateCurrent);
}

Context@ RelativeTickToContext(const uint relativeTick)
{
    Assert(relativeTick >= 2);
    const uint offset = relativeTick - 2;
    return contexts[(contextIndex + offset) % contexts.Length];
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

void AdvanceUnfill(SimulationManager@ sim)
{
    if (steer == prevInputSteer)
        ctx.Remove(InputType::Steer);
    else
        ctx.Set(InputType::Steer, steer);
    Commit(sim);
}

void Commit(SimulationManager@ sim)
{
    contexts[contextIndex++].initialized = false;
    contextIndex %= contexts.Length;
    stepIndex = 0;

    int brake;
    switch (ctx.Get(InputType::Down, brake))
    {
    case IncCommitState::NONE:
        if (preserveBrake)
            ctx.Set(InputType::Down, 1);
    break;
    case IncCommitState::SET:
        Assert(brake == 1);
        if (prevInputBrake == 0)
            ctx.Remove(InputType::Down);
    break;
    default:
        PanicPrint("[Input Simplifier] Unexpected state for brake!");
    break;
    }

    if (preserveSteer && ctx.Get(InputType::Steer) == IncCommitState::NONE)
        ctx.Set(InputType::Steer, preservedInputSteer);

    IncCommit(sim, ctx);
    ctx.Reset();
}


} // namespace InputSimplifier
