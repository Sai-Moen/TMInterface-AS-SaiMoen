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
    IncModeRegister("Input Simplifier", mode);
}

const string VAR = ::Core::VAR + "input_simplifier_";

const string VAR_LOOKAHEAD = VAR + "lookahead";
const ms DEFAULT_LOOKAHEAD = 400;

const string VAR_MINIMIZE_BRAKE = VAR + "minimize_brake";
const string VAR_MAGNITUDE      = VAR + "magnitude";

const string VAR_ORDERED_STRATEGY_INDICES = VAR + "ordered_strategy_indices";

void VarsRegister()
{
    RegisterVariable(VAR_LOOKAHEAD, DEFAULT_LOOKAHEAD);
    RegisterVariable(VAR_MINIMIZE_BRAKE, false);
    RegisterVariable(VAR_MAGNITUDE, 0);
    RegisterVariable(VAR_ORDERED_STRATEGY_INDICES, "");
}

ms varLookahead;
bool varMinimizeBrake;
int varMagnitude;

array<Strategy> varOrderedStrategyIndices(ORDERED_STRATEGY_LEN);

void VarsInit()
{
    varLookahead = VarGetTime(VAR_LOOKAHEAD);
    if (varLookahead < 20)
    {
        varLookahead = 20;
        VarSetTime(VAR_LOOKAHEAD, varLookahead);
    }

    varMinimizeBrake = VarGetBool(VAR_MINIMIZE_BRAKE);

    varMagnitude = VarGetInt(VAR_MAGNITUDE);
    const int clampedMagnitude = Math::Abs(SteerClamp(varMagnitude));
    if (varMagnitude != clampedMagnitude)
    {
        varMagnitude = clampedMagnitude;
        VarSetInt(VAR_MAGNITUDE, varMagnitude);
    }

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
    varLookahead = UI::InputTimeVar("Lookahead", VAR_LOOKAHEAD, 10);
    TooltipOnHover(
        "A lower lookahead makes the simplifier run faster,"
        " but may cause it to desync in an unrecoverable way (default: " + DEFAULT_LOOKAHEAD + "ms).");

    varMinimizeBrake = UI::CheckboxVar("Minimize Brake", VAR_MINIMIZE_BRAKE);
    TooltipOnHover(
        "If this is enabled, the amount of time spent braking will be made as small as possible.\n"
        "The trade-off is that this may introduce more brake inputs.");

    varMagnitude = UI::InputInt("Magnitude", varMagnitude);
    varMagnitude = Math::Abs(SteerClamp(varMagnitude));
    VarSetInt(VAR_MAGNITUDE, varMagnitude);
    TooltipOnHover(
        "This is the magnitude used by the sign-magnitude strategy, where only input direction matters.\n"
        "Setting this to 0 will skip this strategy altogether.");

    UI::Separator();

    UI::TextWrapped("Strategy Order:");
    bool changed = false;
    for (uint i = 0; i < ORDERED_STRATEGY_LEN; ++i)
    {
        const Strategy strategy = varOrderedStrategyIndices[i];

        UI::TextWrapped((i + 1) + ".");
        UI::SameLine();
        const bool down = UI::Button("-##" + i);
        UI::SameLine();
        const bool up = UI::Button("+##" + i);
        UI::SameLine();
        switch (strategy)
        {
        case Strategy::SIGN_MAGNITUDE:
            if (varMagnitude == 0)
            {
                UI::TextDimmed(ORDERED_STRATEGY_NAMES[strategy]);
                break;
            }
        // fallthrough
        default:
            UI::TextWrapped(ORDERED_STRATEGY_NAMES[strategy]);
        break;
        }

        const uint direction = (down ? 1 : 0) - (up ? 1 : 0);
        if (direction == 0)
            continue;

        changed = true;

        const uint offset = direction + ORDERED_STRATEGY_LEN;
        const uint index = (i + offset) % ORDERED_STRATEGY_LEN;
        varOrderedStrategyIndices[i] = varOrderedStrategyIndices[index];
        varOrderedStrategyIndices[index] = strategy;
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
    StepSignMagnitude,
    StepRemoval
};

array<OnStep@> steps;
uint stepIndex;

void Begin(SimulationManager@)
{
    VarsInit();

    IncFetchSet(varLookahead);
    contexts.Resize(varLookahead / 10 - 1);

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
            if (varMagnitude == 0)
                continue;
        break;
        }

        steps.Add(ORDERED_STRATEGY_CALLBACKS[strategy]);
    }
}

void Step(SimulationManager@ sim)
{
    steps[stepIndex](sim);
}

void End(SimulationManager@)
{
    contexts.Clear();
    steps.Clear();
    contextIndex = 0;
    stepIndex = 0;

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
        steer0 = SteerFromUnit(svc.InputSteer);

        preserveBrake = fillBrake && brake0 != 1;
        if (preserveBrake)
        {
            Assert(minimizeBrake);
            IncInputSet(sim, InputType::Down, 1);
        }

        preserveSteer = fillSteer && steer0 != preservedSteer;
        if (preserveSteer)
            IncInputSet(sim, InputType::Steer, preservedSteer);

        return;
    case 1:
        brake1       = int(svc.InputBrake);
        steer1       = SteerFromUnit(svc.InputSteer);
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
    if (time == varLookahead)
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
    else if (time == varLookahead)
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
        steer = SteerFromUnit(turningRate2, turningRate2 - turningRate1);
        IncInputSet(sim, InputType::Steer, steer);
    // fallthrough
    case 1:
        return;
    }

    if (Desynced(sim, tick))
    {
        NextStep(sim);
    }
    else if (time == varLookahead)
    {
        IncStageSet(InputType::Steer, steer);
        Forward(sim);
    }
}

void StepSignMagnitude(SimulationManager@ sim)
{
    const ms time = IncTimeGetRelative(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        steer = GetSign(steer1) * varMagnitude;
        IncInputSet(sim, InputType::Steer, steer);
    // fallthrough
    case 1:
        return;
    }

    if (Desynced(sim, tick))
    {
        NextStep(sim);
    }
    else if (time == varLookahead)
    {
        IncStageSet(InputType::Steer, steer);
        Forward(sim);
    }
}

void StepRemoval(SimulationManager@ sim)
{
    const ms time = IncTimeGetRelative(sim);
    const uint tick = time / 10;
    switch (tick)
    {
    case 0:
        steer = steer0;
        IncInputSet(sim, InputType::Steer, steer);
    // fallthrough
    case 1:
        return;
    }

    if (Desynced(sim, tick))
    {
        NextStep(sim);
    }
    else if (time == varLookahead)
    {
        IncStageSet(InputType::Steer, steer);
        Forward(sim);
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
        Forward(sim);
        return;
    }

    IncRewindPreserve(sim);
    Step(sim);
}

void Forward(SimulationManager@ sim)
{
    contexts[contextIndex++].initialized = false;
    contextIndex %= contexts.Length;
    stepIndex = 0;

    int brake;
    switch (IncStageGet(InputType::Down, brake))
    {
    case IncStageState::NONE:
        if (preserveBrake)
            IncStageSet(InputType::Down, 1);
        else if (brake0 == 0 && IncInputGetRelative(sim, 0, InputType::Down, brake) && brake == 0)
            IncStageRemove(InputType::Down); // Clean up unbalanced rel down inputs.
    break;
    case IncStageState::SET:
        Assert(brake == 0);
        if (brake0 == 0)
            IncStageRemove(InputType::Down);
    break;
    case IncStageState::REMOVE:
        // Unreachable.
    // fallthrough
    default:
        print("[Input Simplifier] Unexpected state for brake!", Severity::Error);
        IncPanic(sim);
        return;
    }

    int steer;
    switch (IncStageGet(InputType::Steer, steer))
    {
    case IncStageState::NONE:
        if (preserveSteer)
            IncStageSet(InputType::Steer, preservedSteer);
    break;
    case IncStageState::SET:
        // NOTE: this does not work in run mode...
        // Therefore, we rely on ToCommandsText to unfill, which it only seems to do for steer, but that works for us!

        // if (steer0 == steer)
        //     IncStageRemove(InputType::Steer);
    break;
    case IncStageState::REMOVE:
        // Unreachable.
    // fallthrough
    default:
        print("[Input Simplifier] Unexpected state for steer!", Severity::Error);
        IncPanic(sim);
        return;
    }

    IncForward(sim);
}


} // namespace InputSimplifier
