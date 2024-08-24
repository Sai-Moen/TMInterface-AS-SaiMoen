namespace InputSimplifier
{


void Main()
{
    RegisterSettings();
    IncRegisterMode("Input Simplifier", Mode());
}

class Mode : IncMode
{
    SupportsUnlockedTimerange { get { return false; } }

    void RenderSettings() { IS::RenderSettings(); }

    void OnBegin(SimulationManager@ simManager) { IS::OnBegin(simManager); }
    void OnStep(SimulationManager@ simManager) { IS::OnStep(simManager); }
    void OnEnd(SimulationManager@) {}
}

const string VAR = Settings::VAR + "simplify_inputs_";

const string VAR_CONTEXT_TIMESPAN = VAR + "context_timespan";
const ms MIN_CTX_TIMESPAN = utils::TickToMs(2);
const ms DEF_CTX_TIMESPAN = utils::TickToMs(25);
const string DEF_TIMESPAN_TEXT = "(default " + DEF_CTX_TIMESPAN + "ms)";
ms varContextTimespan;

const string VAR_STRATEGY_INDICES = VAR + "strategy_indices";
const string STRATEGY_SEP = ",";
array<Strategy> varStrategyIndices(STRATEGY_LEN);

const string VAR_MAGNITUDE = VAR + "air_magnitude";
int varMagnitude;

const string VAR_MINIMIZE_BRAKE = VAR + "minimize_brake";
bool varMinimizeBrake;

void RegisterSettings()
{
    RegisterVariable(VAR_CONTEXT_TIMESPAN, DEF_CTX_TIMESPAN);
    RegisterVariable(VAR_STRATEGY_INDICES, "");
    RegisterVariable(VAR_MAGNITUDE, 0);
    RegisterVariable(VAR_MINIMIZE_BRAKE, false);

    varContextTimespan = ms(GetVariableDouble(VAR_CONTEXT_TIMESPAN));
    DeserializeStrategyIndicesFromVar();
    varMagnitude = int(GetVariableDouble(VAR_MAGNITUDE));
    varMinimizeBrake = GetVariableBool(VAR_MINIMIZE_BRAKE);
}

void DeserializeStrategyIndicesFromVar()
{
    const auto@ const strategies = GetVariableString(VAR_STRATEGY_INDICES).Split(STRATEGY_SEP);
    const uint len = strategies.Length;
    if (len != STRATEGY_LEN)
    {
        SetDefaultStrategyIndices();
        return;
    }

    for (uint i = 0; i < len; i++)
    {
        uint byteCount;
        uint64 parsed = Text::ParseUInt(strategies[i], 10, byteCount);
        if (byteCount == 0 || parsed >= len)
        {
            SetDefaultStrategyIndices();
            return;
        }

        varStrategyIndices[i] = parsed;
    }
}

void SetDefaultStrategyIndices()
{
    for (uint i = 0; i < STRATEGY_LEN; i++)
        varStrategyIndices[i] = i;
}

void RenderSettings()
{
    varContextTimespan = UI::InputTimeVar("Context Timespan", VAR_CONTEXT_TIMESPAN, TICK);
    UI::TextDimmed("Lower timespan is faster, but may desync in an unrecoverable way " + DEF_TIMESPAN_TEXT + ".");

    UI::Separator();

    UI::TextWrapped("Strategy Order:");
    bool changed = false;
    for (uint i = 0; i < STRATEGY_LEN; i++)
    {
        const Strategy strategy = varStrategyIndices[i];

        const bool pressed = UI::Button("Move Down##" + i);
        UI::SameLine();
        switch (strategy)
        {
        case Strategy::SignMagnitude:
            if (varMagnitude == 0)
            {
                UI::TextDimmed(strategyNames[strategy]);
                break;
            }
        default:
            UI::TextWrapped(strategyNames[strategy]);
        }

        if (!pressed)
            continue;

        changed = true;
        const uint nextIndex = i + 1;
        if (nextIndex < STRATEGY_LEN)
        {
            varStrategyIndices[i] = varStrategyIndices[nextIndex];
            varStrategyIndices[nextIndex] = strategy;
        }
    }

    if (changed)
    {
        array<string> strategies(STRATEGY_LEN);
        for (uint i = 0; i < STRATEGY_LEN; i++)
            strategies[i] = Text::FormatUInt(varStrategyIndices[i]);
        SetVariable(VAR_STRATEGY_INDICES, Text::Join(strategies, STRATEGY_SEP));
    }

    UI::Separator();

    varMagnitude = UI::InputIntVar("Magnitude", VAR_MAGNITUDE);
    varMagnitude = ClampSteer(varMagnitude);
    UI::TextDimmed("This is the magnitude used by steering inputs in the air, where only input direction matters.");
    UI::TextDimmed("Setting this to 0 will skip the air input strategy altogether.");

    UI::Separator();

    varMinimizeBrake = UI::CheckboxVar("Minimize Brake", VAR_MINIMIZE_BRAKE);
    UI::TextDimmed("If this is enabled, the amount of time spent braking will be made as small as possible.");
    UI::TextDimmed("The trade-off is that this may introduce more brake inputs.");
}

class Context
{
    vec3 position;
    mat3 rotation;
    vec3 linearSpeed;
    vec3 angularSpeed;

    Context(const TM::HmsStateDyna@ const dyna)
    {
        const iso4 location = dyna.Location;
        position = location.Position;
        rotation = location.Rotation;
        linearSpeed = dyna.LinearSpeed;
        angularSpeed = dyna.AngularSpeed;
    }

    bool opEquals(const Context@ const other)
    {
        return
            EqualsVec3(position, other.position) &&
            EqualsMat3(rotation, other.rotation) &&
            EqualsVec3(linearSpeed, other.linearSpeed) &&
            EqualsVec3(angularSpeed, other.angularSpeed);
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

array<Context@> contexts;

enum Strategy
{
    TurningRate,
    SignMagnitude,
    Removal,

    MinimizeBrake,

    Count
}

const uint STRATEGY_LEN = strategyNames.Length;

const array<string> strategyNames =
{
    "Turning Rate",
    "Sign-Magnitude",
    "Removal"
};

const array<OnSim@> strategyCallbacks =
{
    OnStepTurningRate,
    OnStepAir,
    OnStepRemoval
};

ms contextTimespan;

uint stratIndex;
const uint stratLen = Strategy::Count + 1;
array<OnSim@> strats(stratLen);

void OnBegin(SimulationManager@ simManager)
{
    contextTimespan = Math::Max(MIN_CTX_TIMESPAN, varContextTimespan);
    contexts.Resize(utils::MsToTick(contextTimespan) - 1);

    uint stratsAdded = 0;
    if (varMinimizeBrake)
        @strats[stratsAdded++] = OnStepMinimizeBrake;

    const uint len = varStrategyIndices.Length;
    for (uint i = 0; i < len; i++)
    {
        const Strategy strategy = varStrategyIndices[i];
        switch (strategy)
        {
        case Strategy::SignMagnitude:
            if (varMagnitude == 0)
                continue;
        }

        @strats[stratsAdded++] = strategyCallbacks[strategy];
    }

    while (stratsAdded < stratLen)
        @strats[stratsAdded++] = null;

    SetVariable(VAR_MAGNITUDE, varMagnitude);

    Reset();
}

const OnSim@ onStep;

void OnStep(SimulationManager@ simManager)
{
    onStep(simManager);
}

float prevInputBrake;
int prevInputSteer;

float oldInputBrake;
int oldInputSteer;
float oldTurningRate;

bool isBraking;

float nextInputBrake;
float nextTurningRate;

void OnStepScan(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    const auto@ const svc = simManager.SceneVehicleCar;
    switch (utils::MsToTick(time))
    {
    case 0:
        prevInputBrake = svc.InputBrake;
        prevInputSteer = ToSteer(svc.InputSteer);
        return;
    case 1:
        oldInputBrake = svc.InputBrake;
        oldInputSteer = ToSteer(svc.InputSteer);
        oldTurningRate = svc.TurningRate;

        // if the next tick does not have an input, we must add it to avoid overriding the intended inputSteer
        auto@ const buffer = simManager.InputEvents;
        if (buffer.Find(time, InputType::Steer).IsEmpty())
            Eval::AddInput(buffer, time, InputType::Steer, oldInputSteer);

        // only do this stuff if we are able to remove it later
        isBraking = varMinimizeBrake && oldInputBrake != 0;

        const bool mustAddDownPress =
            isBraking &&                                  // no point in releasing if we aren't pressing
            prevInputBrake == oldInputBrake &&            // no point in pressing if we are already pressing @ input time
            buffer.Find(time, InputType::Down).IsEmpty(); // catches edge cases like a 1-tick brake
        if (mustAddDownPress)
            Eval::AddInput(buffer, time, InputType::Down, 1);

        return;
    case 2:
        nextInputBrake = svc.InputBrake;
        nextTurningRate = svc.TurningRate;
    }

    const uint index = TimeToContextIndex(time);
    @contexts[index] = Context(simManager.Dyna.RefStateCurrent);

    if (time == contextTimespan)
    {
        NextStrategy(simManager);
        Eval::Rewind(simManager);
    }
}

void OnStepMinimizeBrake(SimulationManager@ simManager)
{
    if (!isBraking)
    {
        NextStrategy(simManager);
        Eval::Rewind(simManager);
        return;
    }

    const ms time = IncGetRelativeTime(simManager);
    switch (utils::MsToTick(time))
    {
    case 0:
        Eval::AddInput(simManager, time, InputType::Down, 0);
    case 1:
        return;
    }

    if (Desynced(simManager, time))
    {
        SetDown(simManager, 1);
    }
    else if (time == contextTimespan)
    {
        SetDown(simManager, 0);
        if (nextInputBrake == 0)
        {
            auto@ const buffer = simManager.InputEvents;
            const auto@ const indices = buffer.Find(Eval::Time::input + TICK, InputType::Down, 0);
            BufferRemoveIndices(buffer, indices);
        }
    }
    else
    {
        return;
    }

    Eval::Rewind(simManager);
}

int steer;

void OnStepTurningRate(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    switch (utils::MsToTick(time))
    {
    case 0:
        steer = RoundAway(nextTurningRate * STEER::FULL, nextTurningRate - oldTurningRate);
        Eval::AddInput(simManager, time, InputType::Steer, steer);
    case 1:
        return;
    }

    if (Desynced(simManager, time))
        NextStrategy(simManager);
    else if (time == contextTimespan)
        AdvanceUnfill(simManager);
    else
        return;

    Eval::Rewind(simManager);
}

void OnStepAir(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    switch (utils::MsToTick(time))
    {
    case 0:
        steer = Sign(oldInputSteer) * varMagnitude;
        Eval::AddInput(simManager, time, InputType::Steer, steer);
    case 1:
        return;
    }

    if (Desynced(simManager, time))
        NextStrategy(simManager);
    else if (time == contextTimespan)
        AdvanceUnfill(simManager);
    else
        return;

    Eval::Rewind(simManager);
}

void OnStepRemoval(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    switch (utils::MsToTick(time))
    {
    case 0:
        Eval::RemoveInputs(simManager, time, InputType::Steer);
    case 1:
        return;
    }

    if (Desynced(simManager, time))
    {
        NextStrategy(simManager);
    }
    else if (time == contextTimespan)
    {
        // we already cleaned up the inputs by the nature of this strategy
        Eval::AdvanceNoCleanup();
        Reset();
    }
    else
    {
        return;
    }

    Eval::Rewind(simManager);
}

void Reset()
{
    stratIndex = 0;
    @onStep = OnStepScan;
}

bool Desynced(SimulationManager@ simManager, const ms time)
{
    const uint index = TimeToContextIndex(time);
    return contexts[index] != Context(simManager.Dyna.RefStateCurrent);
}

uint TimeToContextIndex(const ms time)
{
    return utils::MsToTick(time) - 2;
}

void NextStrategy(SimulationManager@ simManager)
{
    @onStep = strats[stratIndex++];
    if (onStep is null)
    {
        print("Desynchronized, restoring old steering value...", Severity::Warning);
        Eval::Advance(simManager, oldInputSteer);
        Reset();
    }
}

void AdvanceUnfill(SimulationManager@ simManager)
{
    if (steer == prevInputSteer)
        Eval::AdvanceNoAdd(simManager);
    else
        Eval::Advance(simManager, steer);
    Reset();
}

void SetDown(SimulationManager@ simManager, const int value)
{
    Eval::RemoveInputs(simManager, Eval::Time::input, InputType::Down);
    if (value != prevInputBrake)
        Eval::AddInput(simManager, Eval::Time::input, InputType::Down, value);
    NextStrategy(simManager);
}


} // namespace SI
