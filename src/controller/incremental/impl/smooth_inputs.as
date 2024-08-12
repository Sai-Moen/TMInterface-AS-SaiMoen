namespace SI
{


const string NAME = "Simplify Inputs";
const string DESCRIPTION = "Tries to simplifiy inputs using turning rate and airtime input removal.";
const Mode@ const mode = Mode(
    NAME, DESCRIPTION,
    null, null,
    OnBegin, OnStep
);

void OnBegin(SimulationManager@ simManager)
{
    Reset();
}

const OnSim@ onStep;

void OnStep(SimulationManager@ simManager)
{
    onStep(simManager);
}

int oldInputSteer;
float oldTurningRate1;
float oldTurningRate2;
TM::HmsStateDyna@ oldStateDyna;

void OnStepScan(SimulationManager@ simManager)
{
    const ms time = simManager.RaceTime;
    if (Eval::IsInputTime(time))
        return;

    const auto@ const svc = simManager.SceneVehicleCar;
    if (Eval::IsEvalTime(time))
    {
        oldTurningRate2 = svc.TurningRate;
        @oldStateDyna = simManager.Dyna.CurrentState;

        Eval::Rewind(simManager);
        @onStep = OnStepTurningRate;
    }
    else
    {
        oldInputSteer = ToSteer(svc.InputSteer);
        oldTurningRate1 = svc.TurningRate;
    }
}

int steer;

void OnStepTurningRate(SimulationManager@ simManager)
{
    const ms time = simManager.RaceTime;
    if (Eval::IsInputTime(time))
    {
        steer = RoundAway(oldTurningRate2 * STEER::FULL, oldTurningRate2 - oldTurningRate1);
        Eval::AddInput(simManager, time, InputType::Steer, steer);
    }
    else if (Eval::IsEvalTime(time))
    {
        if (StillSynced(simManager))
        {
            Eval::Advance(simManager, steer);
            Reset();
        }
        else
        {
            @onStep = OnStepRemoval;
        }
        Eval::Rewind(simManager);
    }
}

void OnStepRemoval(SimulationManager@ simManager)
{
    const ms time = simManager.RaceTime;
    if (Eval::IsInputTime(time))
    {
        Eval::RemoveInputs(simManager, time, InputType::Steer);
    }
    else if (Eval::IsEvalTime(time))
    {
        if (StillSynced(simManager))
        {
            Eval::Advance();
        }
        else
        {
            Eval::Advance(simManager, oldInputSteer);
        }
        Reset();
        Eval::Rewind(simManager);
    }
}

void Reset()
{
    oldInputSteer = 0;
    oldTurningRate1 = 0;
    oldTurningRate2 = 0;

    steer = 0;

    Eval::Time::OffsetEval(TWO_TICKS);
    @onStep = OnStepScan;
}

bool StillSynced(SimulationManager@ simManager)
{
    const auto@ const current = simManager.Dyna.RefStateCurrent;

    const iso4 oldLocation = oldStateDyna.Location;
    const iso4 newLocation = current.Location;
    return
        EqualsVec3(newLocation.Position, oldLocation.Position) &&
        EqualsMat3(newLocation.Rotation, oldLocation.Rotation) &&
        EqualsVec3(current.LinearSpeed, oldStateDyna.LinearSpeed) &&
        EqualsVec3(current.AngularSpeed, oldStateDyna.AngularSpeed);
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


} // namespace SI
