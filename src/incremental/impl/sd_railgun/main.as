namespace SpeedDrift
{


void Main()
{
    VarsRegister();
    VarsInit();

    IncMode mode;
    mode.excludedInputTypes = { InputType::Left, InputType::Right, InputType::Steer };
    @mode.draw = Draw;
    @mode.begin = Begin;
    @mode.step = Step;
    @mode.end = End;
    IncModeRegister("SD Railgun", mode);
}

const string VAR = ::Core::VAR + "sd_";

const string VAR_QUALITY_THRESHOLD = VAR + "quality_threshold";
const string VAR_LOOKAHEAD_QUALITY = VAR + "lookahead_quality";
const string VAR_LOOKAHEAD_NORMAL  = VAR + "lookahead_normal";

void VarsRegister()
{
    RegisterVariable(VAR_QUALITY_THRESHOLD, 0.25);
    RegisterVariable(VAR_LOOKAHEAD_QUALITY, 60);
    RegisterVariable(VAR_LOOKAHEAD_NORMAL,  120);
}

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
    if (varLookaheadQuality < 20)
    {
        varLookaheadQuality = 20;
        VarSetTime(VAR_LOOKAHEAD_QUALITY, varLookaheadQuality);
    }

    varLookaheadNormal = VarGetTime(VAR_LOOKAHEAD_NORMAL);
    if (varLookaheadNormal < 20)
    {
        varLookaheadNormal = 20;
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

    varLookaheadQuality = UI::InputTimeVar("Quality Lookahead", VAR_LOOKAHEAD_QUALITY, 10);
    TooltipOnHover("Can be set as low as 20ms, but it's a bit shaky, 60ms by default.");

    UI::EndDisabled();

    varLookaheadNormal = UI::InputTimeVar("Normal Lookahead", VAR_LOOKAHEAD_NORMAL, 10);
    TooltipOnHover(
        "Can be set as low as 20ms, but depending on speed you might want up to 130ms-140ms"
        " (lowest working in a test was 50ms-60ms at close to speed cap), 120ms by default.");
}

void Begin(SimulationManager@)
{
    VarsInit();
    evalState = EvalState::INIT;
}

void End(SimulationManager@)
{
    fallback = false;
    last = false;
    haveTurningRates = false;
}

const int RANGE_SIZE = 4;
const int STEP_LAST_DEVIATION = RANGE_SIZE / 2;

enum EvalState
{
    NONE,

    INIT,
    EVALUATE,
}

EvalState evalState;

bool fallback;
bool last;

bool haveTurningRates;
float turningRate0;
float turningRate1;

bool useQuality;

int bestSteer;
float bestResult;
ms lookahead;

int steer;
int steerStep;
int steerBound;

bool rewinding;

void Step(SimulationManager@ sim)
{
    do
    {
        rewinding = false;

        const ms time = IncTimeGetRelative(sim);
        switch (evalState)
        {
        case EvalState::INIT:
            if (!fallback)
            {
                const float turningRate = sim.SceneVehicleCar.TurningRate;
                if (!haveTurningRates)
                {
                    haveTurningRates = true;
                    turningRate0 = turningRate;
                    return;
                }
                haveTurningRates = false;
                turningRate1 = turningRate;

                Rewind(sim);

                useQuality = varQualityThreshold != 0;
            }
            fallback = false;
            evalState = EvalState::EVALUATE;

            bestSteer = SteerFromUnit(turningRate1, turningRate1 - turningRate0);
            bestResult = useQuality ? 1 : -1;
            lookahead = useQuality ? varLookaheadQuality : varLookaheadNormal;

            steerStep = 0x8000 / RANGE_SIZE;
            SetSteerBounds();
        break;
        case EvalState::EVALUATE:
            if (time == 0)
            {
                IncInputSet(sim, InputType::Steer, steer);
                break;
            }

            Assert(time <= lookahead);
            if (time != lookahead)
                break;

            {
                float result;
                bool isBetter;
                if (useQuality)
                {
                    result = Math::Abs(1 - ComputeSpeedslideQualityForStadiumCar(sim));
                    isBetter = result < bestResult;
                }
                else
                {
                    result = sim.Dyna.RefStateCurrent.LinearSpeed.Length();
                    isBetter = result > bestResult;
                }

                if (isBetter)
                {
                    bestResult = result;
                    bestSteer = steer;
                }
            }

            if (last)
            {
                last = false;
                evalState = EvalState::INIT;
                if (!useQuality || bestResult <= varQualityThreshold)
                {
                    IncStageSet(InputType::Steer, bestSteer);
                    IncForward(sim);
                    return;
                }

                useQuality = false;
                fallback = true;
            }
            else
            {
                steer += steerStep;
                if (steer > steerBound)
                {
                    steerStep >>= 1;
                    last = steerStep == 0;
                    if (last)
                    {
                        steerStep = 1;
                        SetSteerBoundsWithOffset(STEP_LAST_DEVIATION);
                    }
                    else
                    {
                        SetSteerBounds();
                    }
                }
            }

            Rewind(sim);
        break;
        default:
            Unreachable();
        break;
        }
    } while (rewinding);
}

void SetSteerBounds()
{
    SetSteerBoundsWithOffset(steerStep * (RANGE_SIZE - 1) / 2);
}

void SetSteerBoundsWithOffset(const int offset)
{
    steer      = SteerClamp(bestSteer - offset);
    steerBound = SteerClamp(bestSteer + offset);
}

void Rewind(SimulationManager@ sim)
{
    IncRewindPreserve(sim);
    rewinding = true;
}


} // namespace SpeedDrift
