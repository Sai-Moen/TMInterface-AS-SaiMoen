namespace SpeedDrift
{


IncMode mode;

void Main()
{
    Register();

    mode.preservationExclusions = { InputType::Left, InputType::Right, InputType::Steer };

    @mode.draw = Draw;
    @mode.begin = Begin;
    @mode.step = StepInit;
    @mode.end = End;
    IncRegisterMode("SD Railgun", mode);
}

const string VAR = ::Core::VAR + "sd_";

const string VAR_QUALITY_THRESHOLD = VAR + "quality_threshold";
const string VAR_SEEK_QUALITY      = VAR + "seek_quality";
const string VAR_SEEK_NORMAL       = VAR + "seek_normal";

float varQualityThreshold;
ms varSeekQuality;
ms varSeekNormal;

void Register()
{
    RegisterVariable(VAR_QUALITY_THRESHOLD, 0.25);
    RegisterVariable(VAR_SEEK_QUALITY, 60);
    RegisterVariable(VAR_SEEK_NORMAL, 120);

    varQualityThreshold = VarGetFloat(VAR_QUALITY_THRESHOLD);
    varSeekQuality = VarGetMs(VAR_SEEK_QUALITY);
    varSeekNormal  = VarGetMs(VAR_SEEK_NORMAL);
}

// tick 0: input time
// tick 1: input applied
// tick 2: input's effect observed
const ms MINIMUM_SEEK = 20;

void Draw()
{
    varQualityThreshold = UI::SliderFloatVar("Quality Threshold", VAR_QUALITY_THRESHOLD, 0, 1);
    TooltipOnHover(
        "Represents the maximum allowed deviation from a perfect SD, 0.25 by default.\n"
        "0: Never use SD Quality\n"
        "1: Always use SD Quality\n"
        "For anything in between, use Quality first.\n"
        "If the quality deviation exceeds the given threshold, use velocity as a fallback.");

    UI::BeginDisabled(varQualityThreshold == 0);

    varSeekQuality = UI::InputTime("Quality seeking (lookahead) time", varSeekQuality, 10);
    TooltipOnHover("Can be set as low as 20ms, but it's a bit shaky, 60ms by default.");
    if (varSeekQuality < MINIMUM_SEEK)
        varSeekQuality = MINIMUM_SEEK;
    VarSetMs(VAR_SEEK_QUALITY, varSeekQuality);

    UI::EndDisabled();

    varSeekNormal = UI::InputTime("Normal seeking (lookahead) time", varSeekNormal, 10);
    TooltipOnHover(
        "Can be set as low as 20ms, but depending on speed you might want up to 130ms-140ms "
        "(lowest working in a test was 50ms-60ms at close to speed cap), 120ms by default.");
    if (varSeekNormal < MINIMUM_SEEK)
        varSeekNormal = MINIMUM_SEEK;
    VarSetMs(VAR_SEEK_NORMAL, varSeekNormal);
}

void Begin(SimulationManager@ sim)
{
    const float clampedQualityThreshold = Math::Clamp(varQualityThreshold, 0.f, 1.f);
    if (varQualityThreshold != clampedQualityThreshold)
    {
        varQualityThreshold = clampedQualityThreshold;
        VarSetFloat(VAR_QUALITY_THRESHOLD, varQualityThreshold);
    }

    if (varSeekQuality < MINIMUM_SEEK)
    {
        varSeekQuality = MINIMUM_SEEK;
        VarSetMs(VAR_SEEK_QUALITY, varSeekQuality);
    }

    if (varSeekNormal < MINIMUM_SEEK)
    {
        varSeekNormal = MINIMUM_SEEK;
        VarSetMs(VAR_SEEK_NORMAL, varSeekNormal);
    }
}

void End(SimulationManager@)
{
    Reset();
}

const int RANGE_SIZE = 4;
const int STEP_LAST_DEVIATION = RANGE_SIZE / 2;

enum EvalState
{
    NONE,
    LAST,
    COMMIT,
    FALLBACK,
}

bool haveTurningRates;
float turningRate0;
float turningRate1;

EvalState evalState;
bool useQuality;

int bestSteer;
int steer;
array<int> steerHistory;

double bestResult;
double result;

ms seek;
int step;
int bound;

// NOTE: right now the steering on the input time is nuked too early, so the turning rates will just be the same.
// Will look again if/when we get API's with more control over the input event buffer in different context modes.
// E.g. RewindToState not removing input events in run mode (and actually playing them without needing SetInputState).
void StepInit(SimulationManager@ sim)
{
    if (evalState != EvalState::FALLBACK)
    {
        const float turningRate = sim.SceneVehicleCar.TurningRate;
        if (!haveTurningRates)
        {
            turningRate0 = turningRate;
            haveTurningRates = true;
            return;
        }
        turningRate1 = turningRate;
        haveTurningRates = false;
        IncRewindPreserve(sim);

        useQuality = varQualityThreshold != 0;
    }
    evalState = EvalState::NONE;

    bestSteer = RoundAway(turningRate1 * STEER_FULL, turningRate1 - turningRate0);
    bestResult = useQuality ? 1 : -1;

    seek = useQuality ? varSeekQuality : varSeekNormal;
    step = 0x8000 / RANGE_SIZE;
    SetSteerBounds();

    @mode.step = StepMain;
    StepMain(sim);
}

void StepMain(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(sim);
    if (time == 0)
    {
        while (steer <= bound)
        {
            steer += step;
            if (steerHistory.Find(steer) == -1)
            {
                steerHistory.Add(steer);
                IncInputSet(sim, InputType::Steer, steer);
                break;
            }
        }
    }
    else if (time == seek)
    {
        Evaluate(sim);
        if (evalState != EvalState::COMMIT)
        {
            IncRewindPreserve(sim);
            mode.step(sim);
        }
    }
}

void Evaluate(SimulationManager@ sim)
{
    if (IsBetter(sim))
    {
        bestResult = result;
        bestSteer = steer;
    }

    if (steer <= bound)
        return;

    if (evalState == EvalState::LAST)
    {
        if (useQuality && bestResult > varQualityThreshold)
        {
            useQuality = false;
            evalState = EvalState::FALLBACK;
        }
        else
        {
            IncCommitContext ctx;
            ctx.Set(InputType::Steer, bestSteer);
            IncCommit(sim, ctx);
            evalState = EvalState::COMMIT;
        }

        Reset();
        return;
    }

    switch (step)
    {
    case 0:
        print("[SD Railgun] step == 0", Severity::Warning);
        step = 1;
    // fallthrough
    case 1:
        SetSteerBoundsWithOffset(STEP_LAST_DEVIATION);
        evalState = EvalState::LAST;
    break;
    default:
        step >>= 1;
        SetSteerBounds();
    break;
    }
}

bool IsBetter(SimulationManager@ sim)
{
    if (useQuality)
    {
        result = Math::Abs(1 - ComputeSpeedslideQualityForStadiumCar(sim));
        return result < bestResult;
    }
    else
    {
        result = sim.Dyna.RefStateCurrent.LinearSpeed.Length();
        return result > bestResult;
    }
}

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
    @mode.step = StepInit;
}


} // namespace SpeedDrift
