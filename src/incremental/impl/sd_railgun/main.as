namespace SpeedDrift
{


void Main()
{
    RegisterSettings();
    IncRegisterMode("SD Railgun", Mode());
}

// tick 0: input time
// tick 1: input applied
// tick 2: input's effect observed
const ms MINIMUM_SEEK = TickToMs(2);

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        varUseQuality = UI::CheckboxVar("Use Quality?", VAR_USE_QUALITY);
        varSeek = UI::InputTimeVar("Seeking (lookahead) time", VAR_SEEK, TICK);
        if (varSeek < MINIMUM_SEEK)
        {
            varSeek = MINIMUM_SEEK;
            SetVariable(VAR_SEEK, varSeek);
        }
    }

    void OnBegin(SimulationManager@ simManager)
    {
        IncRemoveSteeringAhead(simManager);

        if (fallback)
        {
            fallback = false;
            print("Unexpected fallback flag...", Severity::Warning);
        }
        Reset();
    }

    void OnStep(SimulationManager@ simManager)
    {
        onStep(simManager);
    }

    void OnEnd(SimulationManager@)
    {
        Reset();
    }
}

const string VAR = Settings::VAR + "sd_";

const string VAR_USE_QUALITY = VAR + "use_quality";
const string VAR_SEEK = VAR + "seek";

bool varUseQuality;
ms varSeek;

void RegisterSettings()
{
    RegisterVariable(VAR_USE_QUALITY, true);
    RegisterVariable(VAR_SEEK, 120);

    varUseQuality = GetVariableBool(VAR_USE_QUALITY);
    seek = GetConVarTime(VAR_SEEK);
}

const int RANGE_SIZE = 4;
const int STEP_LAST_DEVIATION = RANGE_SIZE / 2;

bool fallback;
bool useQuality;
ms seek;

double bestResult;
double result;

int bestSteer;
int steer;
array<int> steerHistory;

int step;
int bound;
bool done;

funcdef void OnSim(SimulationManager@);
OnSim@ onStep;

void OnStepInit(SimulationManager@ simManager)
{
    if (!fallback)
        useQuality = varUseQuality;

    seek = useQuality ? MINIMUM_SEEK : varSeek;

    const float prevTurningRate = IncGetTrailingState().SceneVehicleCar.TurningRate;
    const float turningRate = simManager.SceneVehicleCar.TurningRate;
    bestSteer = RoundAway(turningRate * STEER_FULL, turningRate - prevTurningRate);
    bestResult = useQuality ? 1 : -1;

    step = 0x8000 / RANGE_SIZE;
    SetSteerBounds();
    done = false;

    @onStep = OnStepMain;
    onStep(simManager);
}

void OnStepMain(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    if (time == 0)
    {
        while (steer <= bound)
        {
            steer += step;
            if (steerHistory.Find(steer) == -1)
            {
                steerHistory.Add(steer);
                IncSetInput(simManager, InputType::Steer, steer);
                break;
            }
        }
    }
    else if (time == seek)
    {
        OnEval(simManager);
        IncRewind(simManager);
    }
}

void OnEval(SimulationManager@ simManager)
{
    if (IsBetter(simManager))
    {
        bestResult = result;
        bestSteer = steer;
    }

    if (steer <= bound)
        return;

    if (done)
    {
        fallback = useQuality && bestResult == 1; // shouldn't need epsilon here (1 - 0 == 1)
        if (fallback)
        {
            useQuality = false;
        }
        else
        {
            IncCommitContext ctx;
            ctx.steer = bestSteer;
            IncCommit(simManager, ctx);
        }

        Reset();
        return;
    }

    switch (step)
    {
    case 0:
        print("step == 0", Severity::Warning);
        step = 1;
        // fallthrough
    case 1:
        SetSteerBoundsWithOffset(STEP_LAST_DEVIATION);
        done = true;
        break;
    default:
        step >>= 1;
        SetSteerBounds();
        break;
    }
}

bool IsBetter(SimulationManager@ simManager)
{
    if (useQuality)
    {
        result = Math::Abs(1 - ComputeSpeedslideQualityForStadiumCar(simManager));
        return result < bestResult;
    }
    else
    {
        result = simManager.Dyna.RefStateCurrent.LinearSpeed.Length();
        return result > bestResult;
    }
}

// Note: relies on side-effect from step
void SetSteerBounds()
{
    SetSteerBoundsWithOffset(step * (RANGE_SIZE - 1) / 2);
}

void SetSteerBoundsWithOffset(const int offset)
{
    steer = ClampSteer(bestSteer - offset);
    bound = ClampSteer(bestSteer + offset);
}

void Reset()
{
    steerHistory.Clear();
    @onStep = OnStepInit;
}


} // namespace SpeedDrift
