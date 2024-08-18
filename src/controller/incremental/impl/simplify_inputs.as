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

const string SMOOTH_FIRST = PREFIX + "smooth_first";
bool smoothFirst;

const string AIR_MAGNITUDE = PREFIX + "air_magnitude";
int airMagnitude;

void OnRegister()
{
    RegisterVariable(CONTEXT_TIMESPAN, DEF_CTX_TIMESPAN);
    RegisterVariable(SMOOTH_FIRST, true);
    RegisterVariable(AIR_MAGNITUDE, 0);

    contextTimespan = ms(GetVariableDouble(CONTEXT_TIMESPAN));
    smoothFirst = GetVariableBool(SMOOTH_FIRST);
    airMagnitude = int(GetVariableDouble(AIR_MAGNITUDE));
}

void OnSettings()
{
    contextTimespan = UI::InputTimeVar("Context Timespan", CONTEXT_TIMESPAN, TICK);
    UI::TextWrapped("Lower timespan is faster, but may desync in an unrecoverable way " + DEF_TIMESPAN_TEXT + ".");

    UI::Separator();

    smoothFirst = UI::CheckboxVar("Smooth First?", SMOOTH_FIRST);
    UI::TextWrapped("Whether to do input smoothing first, or air input handling first.");

    UI::Separator();

    airMagnitude = UI::InputIntVar("Air Input Magnitude", AIR_MAGNITUDE);
    airMagnitude = ClampSteer(airMagnitude);
    UI::TextWrapped("This is the magnitude used by steering inputs in the air, where only input direction matters.");
    UI::TextWrapped("Setting this to 0 will skip the air input strategy altogether.");
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

uint stratIndex;
array<OnSim@> strats;

void OnBegin(SimulationManager@ simManager)
{
    contextTimespan = Math::Max(MIN_CTX_TIMESPAN, contextTimespan);
    SetVariable(CONTEXT_TIMESPAN, contextTimespan);
    contexts.Resize(contextTimespan / TICK - 1);

    strats.Clear();
    if (smoothFirst)
        strats.Add(OnStepTurningRate);
    if (airMagnitude != 0)
        strats.Add(OnStepAir);
    if (!smoothFirst)
        strats.Add(OnStepTurningRate);
    strats.Add(OnStepRemoval);

    SetVariable(AIR_MAGNITUDE, airMagnitude);

    Reset();
}

const OnSim@ onStep;

void OnStep(SimulationManager@ simManager)
{
    onStep(simManager);
}

int prevInputSteer;

int oldInputSteer;
float oldTurningRate1;
float oldTurningRate2;

void OnStepScan(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    const auto@ const svc = simManager.SceneVehicleCar;
    if (Eval::IsInputTime(time))
    {
        prevInputSteer = ToSteer(svc.InputSteer);
        return;
    }

    if (Eval::IsInputTime(time - TICK))
    {
        oldInputSteer = ToSteer(svc.InputSteer);

        // if the next tick does not have an input, we must add it to avoid overriding the intended inputSteer
        auto@ const buffer = simManager.InputEvents;
        const auto@ const indices = buffer.Find(time, InputType::Steer);
        if (indices.IsEmpty())
            Eval::AddInput(buffer, time, InputType::Steer, oldInputSteer);

        oldTurningRate1 = svc.TurningRate;
        return;
    }
    
    if (Eval::IsInputTime(time - TickToMs(2)))
        oldTurningRate2 = svc.TurningRate;

    const uint index = TimeToContextIndex(time);
    @contexts[index] = Context(simManager.Dyna.RefStateCurrent);

    if (Eval::IsEvalTime(time))
    {
        NextStrategy(simManager);
        Eval::Rewind(simManager);
    }
}

int steer;

void OnStepTurningRate(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (Eval::IsInputTime(time))
    {
        steer = RoundAway(oldTurningRate2 * STEER::FULL, oldTurningRate2 - oldTurningRate1);
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

    prevInputSteer = 0;

    oldInputSteer = 0;
    oldTurningRate1 = 0;
    oldTurningRate2 = 0;

    steer = 0;

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
    if (stratIndex < strats.Length)
    {
        @onStep = strats[stratIndex++];
    }
    else
    {
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


} // namespace SI
