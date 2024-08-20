namespace SI
{


const string NAME = "Simplify Inputs";
const string DESCRIPTION = "Tries to simplifiy inputs using turning rate and airtime input removal.";
const Mode@ const mode = Mode(
    NAME, DESCRIPTION,
    OnRegister, OnSettings,
    OnBegin, OnStep
);

const string PREFIX = ::PREFIX + "simplify_inputs_";

const string CONTEXT_TIMESPAN = PREFIX + "context_timespan";
const ms MIN_CTX_TIMESPAN = TickToMs(2);
const ms DEF_CTX_TIMESPAN = TickToMs(25);
const string DEF_TIMESPAN_TEXT = "(default " + DEF_CTX_TIMESPAN + "ms)";
ms contextTimespan;

const string STRATEGIES = PREFIX + "strategies";
const string STRATEGY_SEP = ",";
array<string> strategies;

const string AIR_MAGNITUDE = PREFIX + "air_magnitude";
int airMagnitude;

const string MINIMIZE_BRAKE = PREFIX + "minimize_brake";
bool minimizeBrake;

void OnRegister()
{
    RegisterVariable(CONTEXT_TIMESPAN, DEF_CTX_TIMESPAN);
    RegisterVariable(STRATEGIES, Text::Join(strategyNames, STRATEGY_SEP));
    RegisterVariable(AIR_MAGNITUDE, 0);
    RegisterVariable(MINIMIZE_BRAKE, false);

    contextTimespan = ms(GetVariableDouble(CONTEXT_TIMESPAN));
    strategies = GetVariableString(STRATEGIES).Split(STRATEGY_SEP);
    airMagnitude = int(GetVariableDouble(AIR_MAGNITUDE));
    minimizeBrake = GetVariableBool(MINIMIZE_BRAKE);

    const uint len = strategies.Length;
    if (len != strategyNames.Length)
    {
        strategies = strategyNames;
    }
    else
    {
        for (uint i = 0; i < len; i++)
        {
            if (strategyNames.Find(strategies[i]) == -1)
            {
                strategies = strategyNames;
                break;
            }
        }
    }
}

void OnSettings()
{
    contextTimespan = UI::InputTimeVar("Context Timespan", CONTEXT_TIMESPAN, TICK);
    UI::TextDimmed("Lower timespan is faster, but may desync in an unrecoverable way " + DEF_TIMESPAN_TEXT + ".");

    UI::Separator();

    UI::TextWrapped("Strategy Order:");
    const uint len = strategies.Length;
    for (uint i = 0; i < len; i++)
    {
        const string strategy = strategies[i];

        const bool pressed = UI::Button("Move Down##" + i);
        UI::SameLine();
        if (IsAirAndNoMagnitude(strategy))
            UI::TextDimmed(strategy);
        else
            UI::TextWrapped(strategy);

        if (!pressed)
            continue;

        const uint nextIndex = i + 1;
        if (nextIndex < len)
        {
            strategies[i] = strategies[nextIndex];
            strategies[nextIndex] = strategy;
        }
    }
    SetVariable(STRATEGIES, Text::Join(strategies, STRATEGY_SEP));

    UI::Separator();

    airMagnitude = UI::InputIntVar("Air Input Magnitude", AIR_MAGNITUDE);
    airMagnitude = ClampSteer(airMagnitude);
    UI::TextDimmed("This is the magnitude used by steering inputs in the air, where only input direction matters.");
    UI::TextDimmed("Setting this to 0 will skip the air input strategy altogether.");

    UI::Separator();

    minimizeBrake = UI::CheckboxVar("Minimize Brake", MINIMIZE_BRAKE);
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

uint stratIndex;
const uint stratLen = Strategy::Count + 1;
array<OnSim@> strats(stratLen);

void OnBegin(SimulationManager@ simManager)
{
    contextTimespan = Math::Max(MIN_CTX_TIMESPAN, contextTimespan);
    SetVariable(CONTEXT_TIMESPAN, contextTimespan);
    contexts.Resize(contextTimespan / TICK - 1);

    uint stratsAdded = 0;
    if (minimizeBrake)
        @strats[stratsAdded++] = OnStepMinimizeBrake;

    const uint len = strategies.Length;
    for (uint i = 0; i < len; i++)
    {
        const string strategy = strategies[i];
        if (IsAirAndNoMagnitude(strategy))
            continue;

        const int index = strategyNames.Find(strategy);
        @strats[stratsAdded++] = strategyCallbacks[index];
    }

    while (stratsAdded < stratLen)
        @strats[stratsAdded++] = null;

    SetVariable(AIR_MAGNITUDE, airMagnitude);

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
    const ms time = simManager.TickTime;
    const auto@ const svc = simManager.SceneVehicleCar;
    if (Eval::IsInputTime(time))
    {
        prevInputBrake = svc.InputBrake;
        prevInputSteer = ToSteer(svc.InputSteer);
        return;
    }

    if (Eval::IsInputTime(time - TICK))
    {
        oldInputBrake = svc.InputBrake;
        oldInputSteer = ToSteer(svc.InputSteer);
        oldTurningRate = svc.TurningRate;

        // if the next tick does not have an input, we must add it to avoid overriding the intended inputSteer
        auto@ const buffer = simManager.InputEvents;
        if (buffer.Find(time, InputType::Steer).IsEmpty())
            Eval::AddInput(buffer, time, InputType::Steer, oldInputSteer);

        // only do this stuff if we are able to remove it later
        isBraking = minimizeBrake && oldInputBrake != 0;

        const bool mustAddDownPress =
            isBraking &&                                  // no point in releasing if we aren't pressing
            prevInputBrake == oldInputBrake &&            // no point in pressing if we are already pressing @ input time
            buffer.Find(time, InputType::Down).IsEmpty(); // catches edge cases like a 1-tick brake
        if (mustAddDownPress)
            Eval::AddInput(buffer, time, InputType::Down, 1);

        return;
    }
    
    if (Eval::IsInputTime(time - TickToMs(2)))
    {
        nextInputBrake = svc.InputBrake;
        nextTurningRate = svc.TurningRate;
    }

    const uint index = TimeToContextIndex(time);
    @contexts[index] = Context(simManager.Dyna.RefStateCurrent);

    if (Eval::IsEvalTime(time))
    {
        NextStrategy(simManager);
        Eval::Rewind(simManager);
    }
}

bool IsAirAndNoMagnitude(const string &in strategy)
{
    return strategy == strategyNames[Strategy::SignMagnitude] && airMagnitude == 0;
}

void OnStepMinimizeBrake(SimulationManager@ simManager)
{
    if (!isBraking)
    {
        NextStrategy(simManager);
        Eval::Rewind(simManager);
        return;
    }

    const ms time = simManager.TickTime;
    if (Eval::IsInputTime(time))
    {
        Eval::AddInput(simManager, time, InputType::Down, 0);
        return;
    }
    else if (Eval::IsInputTime(time - TICK))
    {
        return;
    }

    if (Desynced(simManager, time))
    {
        SetDown(simManager, 1);
    }
    else if (Eval::IsEvalTime(time))
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
    const ms time = simManager.TickTime;
    if (Eval::IsInputTime(time))
    {
        steer = RoundAway(nextTurningRate * STEER::FULL, nextTurningRate - oldTurningRate);
        Eval::AddInput(simManager, time, InputType::Steer, steer);
        return;
    }
    else if (Eval::IsInputTime(time - TICK))
    {
        return;
    }

    if (Desynced(simManager, time))
        NextStrategy(simManager);
    else if (Eval::IsEvalTime(time))
        AdvanceUnfill(simManager);
    else
        return;

    Eval::Rewind(simManager);
}

void OnStepAir(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (Eval::IsInputTime(time))
    {
        steer = Sign(oldInputSteer) * airMagnitude;
        Eval::AddInput(simManager, time, InputType::Steer, steer);
        return;
    }
    else if (Eval::IsInputTime(time - TICK))
    {
        return;
    }

    if (Desynced(simManager, time))
        NextStrategy(simManager);
    else if (Eval::IsEvalTime(time))
        AdvanceUnfill(simManager);
    else
        return;

    Eval::Rewind(simManager);
}

void OnStepRemoval(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (Eval::IsInputTime(time))
    {
        Eval::RemoveInputs(simManager, time, InputType::Steer);
        return;
    }
    else if (Eval::IsInputTime(time - TICK))
    {
        return;
    }

    if (Desynced(simManager, time))
    {
        NextStrategy(simManager);
    }
    else if (Eval::IsEvalTime(time))
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

    Eval::Time::OffsetEval(contextTimespan);
    @onStep = OnStepScan;
}

bool Desynced(SimulationManager@ simManager, const ms time)
{
    const uint index = TimeToContextIndex(time);
    return contexts[index] != Context(simManager.Dyna.RefStateCurrent);
}

uint TimeToContextIndex(const ms time)
{
    return (time + contextTimespan - Eval::Time::eval) / TICK - 2;
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
