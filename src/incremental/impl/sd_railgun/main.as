namespace SpeedDrift
{


IncMode mode;

void Main()
{
    VarsRegister();
    VarsInit();

    mode.preservationExclusions = { InputType::Left, InputType::Right, InputType::Steer };

    @mode.draw = Draw;
    @mode.begin = Begin;
    @mode.step = StepInit;
    @mode.end = End;
    IncRegisterMode("SD Railgun", mode);
}

const string VAR = ::Core::VAR + "sd_";

const string VAR_QUALITY_THRESHOLD = VAR + "quality_threshold";
const string VAR_LOOKAHEAD_QUALITY = VAR + "lookahead_quality";
const string VAR_LOOKAHEAD_NORMAL  = VAR + "lookahead_normal";

void VarsRegister()
{
    RegisterVariable(VAR_QUALITY_THRESHOLD, 0.25);
    RegisterVariable(VAR_LOOKAHEAD_QUALITY, 60);
    RegisterVariable(VAR_LOOKAHEAD_NORMAL, 120);
}

const ms CAUSALITY = 20;

float varQualityThreshold;
ms varLookaheadQuality;
ms varLookaheadNormal;

void VarsInit()
{
    varQualityThreshold = VarGetFloat(VAR_QUALITY_THRESHOLD);
    const float clampedQualityThreshold = Math::Clamp(varQualityThreshold, 0.f, 1.f);
    if (varQualityThreshold != clampedQualityThreshold)
    {
        varQualityThreshold = clampedQualityThreshold;
        VarSetFloat(VAR_QUALITY_THRESHOLD, varQualityThreshold);
    }

    varLookaheadQuality = VarGetTime(VAR_LOOKAHEAD_QUALITY);
    if (varLookaheadQuality < CAUSALITY)
    {
        varLookaheadQuality = CAUSALITY;
        VarSetTime(VAR_LOOKAHEAD_QUALITY, varLookaheadQuality);
    }

    varLookaheadNormal = VarGetTime(VAR_LOOKAHEAD_NORMAL);
    if (varLookaheadNormal < CAUSALITY)
    {
        varLookaheadNormal = CAUSALITY;
        VarSetTime(VAR_LOOKAHEAD_NORMAL, varLookaheadNormal);
    }
}

void Draw()
{
    varQualityThreshold = UI::SliderFloatVar("Quality Threshold", VAR_QUALITY_THRESHOLD, 0.f, 1.f);
    TooltipOnHover(
        "Represents the maximum allowed deviation from a perfect SD, 0.25 by default.\n"
        "0: Never use SD Quality\n"
        "1: Always use SD Quality\n"
        "For anything in between, use Quality first.\n"
        "If the quality deviation exceeds the given threshold, use velocity as a fallback.");

    UI::BeginDisabled(varQualityThreshold == 0.f);

    varLookaheadQuality = UI::InputTime("Quality lookahead time", varLookaheadQuality, 10);
    TooltipOnHover("Can be set as low as 20ms, but it's a bit shaky, 60ms by default.");
    if (varLookaheadQuality < CAUSALITY)
        varLookaheadQuality = CAUSALITY;
    VarSetTime(VAR_LOOKAHEAD_QUALITY, varLookaheadQuality);

    UI::EndDisabled();

    varLookaheadNormal = UI::InputTime("Normal lookahead time", varLookaheadNormal, 10);
    TooltipOnHover(
        "Can be set as low as 20ms, but depending on speed you might want up to 130ms-140ms"
        " (lowest working in a test was 50ms-60ms at close to speed cap), 120ms by default.");
    if (varLookaheadNormal < CAUSALITY)
        varLookaheadNormal = CAUSALITY;
    VarSetTime(VAR_LOOKAHEAD_NORMAL, varLookaheadNormal);
}

void Begin(SimulationManager@ sim)
{
    VarsInit();
    @mode.step = StepInit;
}

void End(SimulationManager@)
{
    steerHistory.Reset();

    evalState = EvalState::NONE;
    haveTurningRates = false;
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

EvalState evalState;
bool useQuality;

bool haveTurningRates;
float turningRate0;
float turningRate1;

int bestSteer;
int steer;
IntHashSet steerHistory;

double bestResult;
double result;

ms lookahead;
int steerStep;
int steerBound;

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

    bestSteer  = RoundAway(turningRate1 * STEER_FULL, turningRate1 - turningRate0);
    bestResult = useQuality ? 1 : -1;

    lookahead = useQuality ? varLookaheadQuality : varLookaheadNormal;
    steerStep = 0x8000 / RANGE_SIZE;
    SetSteerBounds();

    @mode.step = StepMain;
    StepMain(sim);
}

void StepMain(SimulationManager@ sim)
{
    const ms time = IncTimeGetRelative(sim);
    if (time == 0)
    {
        while (steer <= steerBound)
        {
            steer += steerStep;
            if (steerHistory.Add(steer))
            {
                IncInputSet(sim, InputType::Steer, steer);
                break;
            }
        }
    }
    else if (time == lookahead)
    {
        Evaluate(sim);
        if (evalState == EvalState::COMMIT)
            return;

        IncRewindPreserve(sim);
        mode.step(sim);
    }
}

void Evaluate(SimulationManager@ sim)
{
    if (IsBetter(sim))
    {
        bestResult = result;
        bestSteer = steer;
    }

    if (steer <= steerBound)
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
            IncStageSet(InputType::Steer, bestSteer);
            IncCommit(sim);
            evalState = EvalState::COMMIT;
        }

        steerHistory.Reset();
        @mode.step = StepInit;
        return;
    }

    switch (steerStep)
    {
    case 0:
        print("[SD Railgun] steerStep == 0", Severity::Error);
        IncTerminate(sim);

        // Using COMMIT to exit as fast as possible.
        evalState = EvalState::COMMIT;
    break;
    case 1:
        SetSteerBoundsWithOffset(STEP_LAST_DEVIATION);
        evalState = EvalState::LAST;
    break;
    default:
        steerStep >>= 1;
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
    SetSteerBoundsWithOffset(steerStep * (RANGE_SIZE - 1) / 2);
}

void SetSteerBoundsWithOffset(const int offset)
{
    steer      = ClampSteer(bestSteer - offset);
    steerBound = ClampSteer(bestSteer + offset);
}


} // namespace SpeedDrift
