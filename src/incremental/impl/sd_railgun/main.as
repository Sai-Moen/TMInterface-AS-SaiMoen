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
        varQualityThreshold = UI::SliderFloatVar("Quality Threshold", VAR_QUALITY_THRESHOLD, 0, 1);
        TooltipOnHover(
            "Represents the maximum allowed deviation from a perfect SD, 0.25 by default.\n"
            "0: Never use SD Quality\n"
            "1: Always use SD Quality\n"
            "For anything in between, use Quality first.\n"
            "If the quality deviation exceeds the given threshold, use velocity instead.");

        varSeekQuality = UI::InputTimeVar("Quality seeking (lookahead) time", VAR_SEEK_QUALITY, TICK);
        TooltipOnHover("Can be set as low as 20ms, but it's a bit shaky, 60ms by default.");
        if (varSeekQuality < MINIMUM_SEEK)
        {
            varSeekQuality = MINIMUM_SEEK;
            SetVariable(VAR_SEEK_QUALITY, varSeekQuality);
        }

        varSeekNormal = UI::InputTimeVar("Normal seeking (lookahead) time", VAR_SEEK_NORMAL, TICK);
        TooltipOnHover(
            "Can be set as low as 20ms, but depending on speed you might want up to 130ms-140ms "
            "(lowest working in a test was 50ms-60ms at close to speed cap), 120ms by default.");
        if (varSeekNormal < MINIMUM_SEEK)
        {
            varSeekNormal = MINIMUM_SEEK;
            SetVariable(VAR_SEEK_NORMAL, varSeekNormal);
        }
    }

    void OnBegin(SimulationManager@ simManager)
    {
        IncRemoveSteeringAhead(simManager);

        fallback = false;
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

const string VAR_QUALITY_THRESHOLD = VAR + "quality_threshold";
const string VAR_SEEK_QUALITY      = VAR + "seek_quality";
const string VAR_SEEK_NORMAL       = VAR + "seek_normal";

float varQualityThreshold;
ms varSeekQuality;
ms varSeekNormal;

void RegisterSettings()
{
    RegisterVariable(VAR_QUALITY_THRESHOLD, 0.25);
    RegisterVariable(VAR_SEEK_QUALITY, 60);
    RegisterVariable(VAR_SEEK_NORMAL, 120);

    varQualityThreshold = GetConVarFloat(VAR_QUALITY_THRESHOLD);
    varSeekQuality = GetConVarTime(VAR_SEEK_QUALITY);
    varSeekNormal  = GetConVarTime(VAR_SEEK_NORMAL);
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
        useQuality = varQualityThreshold != 0; // gonna assume UI sets it to exactly 0, no epsilon needed surely...

    seek = useQuality ? varSeekQuality : varSeekNormal;

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
        fallback = useQuality && bestResult > 0.005;
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
