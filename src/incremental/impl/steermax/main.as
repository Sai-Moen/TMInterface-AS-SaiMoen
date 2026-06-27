namespace SteerMax
{


void Main()
{
    VarsRegister();
    VarsInit();

    IncMode mode;
    mode.excludedInputTypes = { InputType::Left, InputType::Right, InputType::Steer };
    @mode.draw = Draw;
    @mode.begin = Begin;
    @mode.iteration = Iteration;
    @mode.step = Step;
    IncModeRegister("SteerMax", mode);
}

const string VAR = ::Core::VAR + "sm_";

const string VAR_LOOKAHEAD_STRATEGY = VAR + "lookahead_strategy";

const string VAR_LOOKAHEAD        = VAR + "lookahead";
const string VAR_TIMEOUT          = VAR + "timeout";
const string VAR_LOOKAHEAD_OFFSET = VAR + "lookahead_offset";
const string VAR_BASE_LOOKAHEAD   = VAR + "base_lookahead";
const string VAR_MAX_ROLLBACK     = VAR + "max_rollback";

const string VAR_STEER_TOWARDS = VAR + "steer_towards";
const string VAR_STEER_AWAY    = VAR + "steer_away";

const string VAR_STEER_OFFSET_STRATEGY = VAR + "steer_offset_strategy";
const string VAR_STEER_OFFSET          = VAR + "steer_offset";
const string VAR_MAX_STEER_OFFSET      = VAR + "max_steer_offset";

const string VAR_MAX_SPEED_LOSS       = VAR + "max_speed_loss";
const string VAR_MAX_SPEED_BLEED      = VAR + "max_speed_bleed";
const string VAR_IGNORE_GEARING_BLEED = VAR + "ignore_gearing_bleed";

const string VAR_NO_WALLBANG = VAR + "no_wallbang";

const string VAR_NO_SLIDE           = VAR + "no_slide";
const string VAR_SLIDING_WHEELS_MIN = VAR + "sliding_wheels_min";
const string VAR_SLIDING_WHEELS_MAX = VAR + "sliding_wheels_max";

void VarsRegister()
{
    RegisterVariable(VAR_LOOKAHEAD_STRATEGY, 0);
    RegisterVariable(VAR_LOOKAHEAD,          200);
    RegisterVariable(VAR_TIMEOUT,            200);
    RegisterVariable(VAR_LOOKAHEAD_OFFSET,   200);
    RegisterVariable(VAR_BASE_LOOKAHEAD,     20);
    RegisterVariable(VAR_MAX_ROLLBACK,       200);

    RegisterVariable(VAR_STEER_TOWARDS, STEER_MAX);
    RegisterVariable(VAR_STEER_AWAY,    STEER_MIN);

    RegisterVariable(VAR_STEER_OFFSET_STRATEGY, 0);
    RegisterVariable(VAR_STEER_OFFSET,          800);
    RegisterVariable(VAR_MAX_STEER_OFFSET,      1024);

    RegisterVariable(VAR_MAX_SPEED_LOSS,       18);
    RegisterVariable(VAR_MAX_SPEED_BLEED,      0.18);
    RegisterVariable(VAR_IGNORE_GEARING_BLEED, true);

    RegisterVariable(VAR_NO_WALLBANG, true);

    RegisterVariable(VAR_NO_SLIDE,           false);
    RegisterVariable(VAR_SLIDING_WHEELS_MIN, 0);
    RegisterVariable(VAR_SLIDING_WHEELS_MAX, 0);
}

enum LookaheadStrategy
{
    ABSOLUTE,
    RELATIVE,
    DYNAMIC,

    COUNT
}

const array<string> LOOKAHEAD_STRATEGY_NAMES =
{
    "Absolute",
    "Relative",
    "Dynamic"
};

LookaheadStrategy varLookaheadStrategy;
ms varLookahead;
ms varTimeout;
ms varLookaheadOffset;
ms varBaseLookahead;
ms varMaxRollback;

int varSteerTowards;
int varSteerAway;

enum SteerOffsetStrategy
{
    OFF,
    MANUAL,
    AUTOMATIC,

    COUNT
}

const array<string> STEER_OFFSET_STRATEGY_NAMES =
{
    "Off",
    "Manual",
    "Automatic"
};

SteerOffsetStrategy varSteerOffsetStrategy;
int varSteerOffset;
int varMaxSteerOffset;

float varMaxSpeedLoss;
float varMaxSpeedBleed;
bool varIgnoreGearingBleed;

bool varNoWallbang;

bool varNoSlide;
uint varSlidingWheelsMin;
uint varSlidingWheelsMax;

void VarsInit()
{
    varLookaheadStrategy = LookaheadStrategy(VarGetUint(VAR_LOOKAHEAD_STRATEGY));
    if (varLookaheadStrategy >= LookaheadStrategy::COUNT)
    {
        varLookaheadStrategy = LookaheadStrategy(0);
        VarSetUint(VAR_LOOKAHEAD_STRATEGY, varLookaheadStrategy);
    }

    varLookahead = VarGetTime(VAR_LOOKAHEAD);
    if (varLookahead < 20)
    {
        varLookahead = 20;
        VarSetTime(VAR_LOOKAHEAD, varLookahead);
    }

    varTimeout = VarGetTime(VAR_TIMEOUT);
    if (varTimeout < 20)
    {
        varTimeout = 20;
        VarSetTime(VAR_TIMEOUT, varTimeout);
    }

    varLookaheadOffset = VarGetTime(VAR_LOOKAHEAD_OFFSET);
    if (varLookaheadOffset < 0)
    {
        varLookaheadOffset = 0;
        VarSetTime(VAR_LOOKAHEAD_OFFSET, varLookaheadOffset);
    }

    varBaseLookahead = VarGetTime(VAR_BASE_LOOKAHEAD);
    if (varBaseLookahead < 20)
    {
        varBaseLookahead = 20;
        VarSetTime(VAR_BASE_LOOKAHEAD, varBaseLookahead);
    }

    varMaxRollback = VarGetTime(VAR_MAX_ROLLBACK);
    if (varMaxRollback < 0)
    {
        varMaxRollback = 0;
        VarSetTime(VAR_MAX_ROLLBACK, varMaxRollback);
    }

    varSteerTowards = VarGetInt(VAR_STEER_TOWARDS);
    const int clampedSteerTowards = SteerClamp(varSteerTowards);
    if (varSteerTowards != clampedSteerTowards)
    {
        varSteerTowards = clampedSteerTowards;
        VarSetInt(VAR_STEER_TOWARDS, varSteerTowards);
    }

    varSteerAway = VarGetInt(VAR_STEER_AWAY);
    const int clampedSteerAway = SteerClamp(varSteerAway);
    if (varSteerAway != clampedSteerAway)
    {
        varSteerAway = clampedSteerAway;
        VarSetInt(VAR_STEER_AWAY, varSteerAway);
    }

    varSteerOffsetStrategy = SteerOffsetStrategy(VarGetUint(VAR_STEER_OFFSET_STRATEGY));
    if (varSteerOffsetStrategy >= SteerOffsetStrategy::COUNT)
    {
        varSteerOffsetStrategy = SteerOffsetStrategy(0);
        VarSetUint(VAR_STEER_OFFSET_STRATEGY, varSteerOffsetStrategy);
    }

    varSteerOffset = VarGetInt(VAR_STEER_OFFSET);
    if (varSteerOffset < 0)
    {
        varSteerOffset = 0;
        VarSetInt(VAR_STEER_OFFSET, varSteerOffset);
    }

    varMaxSteerOffset = VarGetInt(VAR_MAX_STEER_OFFSET);
    if (varMaxSteerOffset < 0)
    {
        varMaxSteerOffset = 0;
        VarSetInt(VAR_MAX_STEER_OFFSET, varMaxSteerOffset);
    }

    varMaxSpeedLoss       = VarGetFloat(VAR_MAX_SPEED_LOSS);
    varMaxSpeedBleed      = VarGetFloat(VAR_MAX_SPEED_BLEED);
    varIgnoreGearingBleed = VarGetBool(VAR_IGNORE_GEARING_BLEED);

    varNoWallbang = VarGetBool(VAR_NO_WALLBANG);
    varNoSlide    = VarGetBool(VAR_NO_SLIDE);

    varSlidingWheelsMin = VarGetUint(VAR_SLIDING_WHEELS_MIN);
    varSlidingWheelsMax = VarGetUint(VAR_SLIDING_WHEELS_MAX);
    if (varSlidingWheelsMax > 4)
    {
        varSlidingWheelsMax = 0;
        VarSetUint(VAR_SLIDING_WHEELS_MAX, varSlidingWheelsMax);
    }

    if (varSlidingWheelsMin > varSlidingWheelsMax)
    {
        varSlidingWheelsMin = varSlidingWheelsMax;
        VarSetUint(VAR_SLIDING_WHEELS_MIN, varSlidingWheelsMin);
    }
}

void Draw()
{
    ComboSelectIndex("Lookahead Strategy", LOOKAHEAD_STRATEGY_NAMES, varLookaheadStrategy, LookaheadStrategyCallback);
    TooltipOnHover(
        "- Absolute: always look ahead a fixed amount of time.\n"
        "- Relative: look ahead from the constraints violation time,"
        " or assume Steer Towards can be used if the timeout is reached.\n"
        "- Dynamic: start with the lowest possible lookahead,"
        " and temporarily increase it when constraints become unavoidable.");

    switch (varLookaheadStrategy)
    {
    case LookaheadStrategy::ABSOLUTE:
        varLookahead = UI::InputTimeVar("Lookahead", VAR_LOOKAHEAD, 10);
        TooltipOnHover(
            "The amount of time to look ahead of the tick being evaluated for constraint violations."
            " (default: 200ms).\n"
            "Should be at least 20ms so there is enough time to react.");
    break;
    case LookaheadStrategy::RELATIVE:
        varTimeout = UI::InputTimeVar("Timeout", VAR_TIMEOUT, 10);
        TooltipOnHover(
            "If the constraints hold for this amount of time, use maximum steering and go to the next tick"
            " (default: 200ms).\n"
            "Should be at least 20ms so there is enough time to react.");

        varLookaheadOffset = UI::InputTimeVar("Lookahead Offset", VAR_LOOKAHEAD_OFFSET, 10);
        TooltipOnHover(
            "If the constraints did not hold, look ahead from the constraint failure time by this amount of time"
            " (default: 200ms).\n"
            "A new steering value will then be determined which does not fail before the lookahead offset.");
    break;
    case LookaheadStrategy::DYNAMIC:
        varBaseLookahead = UI::InputTimeVar("Base Lookahead", VAR_BASE_LOOKAHEAD, 10);
        TooltipOnHover(
            "The base value to look ahead with,"
            " which will be increased temporarily when going further back to avoid failing constraints. (default: 20ms)\n"
            "For noslide, 20ms should be fine.\n"
            "If you want to use it for wallhugging, it will need to be quite a bit higher than that.");

        varMaxRollback = UI::InputTimeVar("Max Rollback", VAR_MAX_ROLLBACK, 10);
        TooltipOnHover(
            "How far the dynamic lookahead system should be able to go backward in time to try to avoid failing constraints"
            " (default: 200ms).\n"
            "Set to 0 for infinite rollback (at least, until it fails at the earliest possible time).");
    break;
    default:
        Unreachable();
    break;
    }

    UI::Separator();

    varSteerTowards = UI::SliderInt("Steer Towards", varSteerTowards, STEER_MIN, STEER_MAX);
    TooltipOnHover(
        "The best steering value allowed.\n"
        "Where 'best' means maximal (but not numerically, rather, 'optimal')");

    const bool left = UI::Button("Left");
    UI::SameLine();
    const bool right = UI::Button("Right");

    varSteerAway = UI::SliderInt("Steer Away", varSteerAway, STEER_MIN, STEER_MAX);
    TooltipOnHover(
        "The worst steering value allowed.\n"
        "Where 'worst' means minimal (but not numerically, rather, 'pessimal')");

    const bool zero = UI::Button("Zero");

    if (left)
    {
        varSteerTowards = STEER_MIN;
        varSteerAway    = STEER_MAX;
    }
    else if (right)
    {
        varSteerTowards = STEER_MAX;
        varSteerAway    = STEER_MIN;
    }
    else
    {
        if (zero)
            varSteerAway = 0;

        if (varSteerTowards == varSteerAway)
        {
            ++varSteerTowards;
            --varSteerAway;
        }

        varSteerTowards = SteerClamp(varSteerTowards);
        varSteerAway    = SteerClamp(varSteerAway);
    }
    VarSetInt(VAR_STEER_TOWARDS, varSteerTowards);
    VarSetInt(VAR_STEER_AWAY,    varSteerAway);

    ComboSelectIndex("Steer Offset Strategy", STEER_OFFSET_STRATEGY_NAMES, varSteerOffsetStrategy, SteerOffsetStrategyCallback);
    TooltipOnHover(
        "- Off: No steer offset.\n"
        "- Manual: Set a fixed steer offset.\n"
        "- Automatic: Automatically determine a steer offset by narrowing it down with multiple runs of an iteration.\n"
        "NOTE: the automatic strategy may take a long time to complete.");

    switch (varSteerOffsetStrategy)
    {
    case SteerOffsetStrategy::OFF:
    break;
    case SteerOffsetStrategy::MANUAL:
        varSteerOffset = UI::InputInt("Steer Offset", varSteerOffset);
        if (varSteerOffset < 0)
            varSteerOffset = 0;
        VarSetInt(VAR_STEER_OFFSET, varSteerOffset);
        TooltipOnHover(
            "After determining a new steering value, offset it (up to) the given offset away (default: 800).\n"
            "Where 'away' means less maximal steering, i.e. Steer Away.\n"
            "This will respect the steering bounds specified above,"
            " hence it may not be able to offset by the requested amount.");
    break;
    case SteerOffsetStrategy::AUTOMATIC:
        varMaxSteerOffset = UI::InputInt("Max Steer Offset", varMaxSteerOffset);
        if (varMaxSteerOffset < 0)
            varMaxSteerOffset = 0;
        VarSetInt(VAR_MAX_STEER_OFFSET, varMaxSteerOffset);
        TooltipOnHover(
            "When refining the steer offset,"
            " this will be used to limit the range of values that can be tried (default: 1024).\n"
            "A lower maximum can result in reducing the amount of checks,"
            " but putting it too low could result in not finding any succeeding steer offset.");
    break;
    default:
        Unreachable();
    break;
    }

    UI::Separator();

    varMaxSpeedLoss = UI::InputFloatVar("Max Speed Loss", VAR_MAX_SPEED_LOSS);
    TooltipOnHover(
        "The maximum cumulative speed loss allowed (default: 18 km/h).\n"
        "This is calculated based on the last time the speed increased, to the tick being measured.");

    varMaxSpeedBleed = UI::InputFloatVar("Max Speed Bleed", VAR_MAX_SPEED_BLEED);
    TooltipOnHover(
        "The maximum immediate (between two consecutive ticks) speed loss allowed (default: 0.18 km/h).\n"
        "Setting this to a negative value will make it behave like a minimum speed gain.");

    varIgnoreGearingBleed = UI::CheckboxVar("Ignore Speed Bleed while Gearing", VAR_IGNORE_GEARING_BLEED);
    TooltipOnHover("If the gearbox is not in the default state, but maxing out or gearing, ignore the speed bleed constraint.");

    varNoWallbang = UI::CheckboxVar("No Wallbang", VAR_NO_WALLBANG);
    TooltipOnHover("Enabling this will count any lateral contact as an immediate failure.");

    varNoSlide = UI::CheckboxVar("No Slide (read NOTE before using)", VAR_NO_SLIDE);
    TooltipOnHover(
        "Enabling this will count any sliding as an immediate failure.\n"
        "NOTE: this setting checks the car's sliding state, which will very quickly report the car as sliding,"
        " even if none of the wheels are sliding.\n"
        "For this reason it will be better (in most cases) to leave this turned off,"
        " and to set the sliding wheels constraints.");

    varSlidingWheelsMin = UI::SliderInt("Min Sliding Wheels", varSlidingWheelsMin, 0, 4);
    TooltipOnHover("The minimum amount of sliding wheels allowed (default: 0).");

    varSlidingWheelsMax = UI::SliderInt("Max Sliding Wheels", varSlidingWheelsMax, 0, 4);
    if (varSlidingWheelsMax > 4)
        varSlidingWheelsMax = 0;
    VarSetUint(VAR_SLIDING_WHEELS_MAX, varSlidingWheelsMax);
    TooltipOnHover("The maximum amount of sliding wheels allowed (default: 0).");

    if (varSlidingWheelsMin > varSlidingWheelsMax)
        varSlidingWheelsMin = varSlidingWheelsMax;
    VarSetUint(VAR_SLIDING_WHEELS_MIN, varSlidingWheelsMin);
}

void LookaheadStrategyCallback(const uint index)
{
    varLookaheadStrategy = LookaheadStrategy(index);
    VarSetUint(VAR_LOOKAHEAD_STRATEGY, varLookaheadStrategy);
}

void SteerOffsetStrategyCallback(const uint index)
{
    varSteerOffsetStrategy = SteerOffsetStrategy(index);
    VarSetUint(VAR_STEER_OFFSET_STRATEGY, varSteerOffsetStrategy);
}

int steerMin;
int steerMax;
int steerDirection;

bool refineSteerOffset;
int steerOffset;
int steerOffsetTowards;
int steerOffsetAway;

float maxSpeedLoss;
float maxSpeedBleed;

ms cacheHint;
ms targetTime;

enum EvalState
{
    SEARCH,
    SCAN,
    EVALUATE,
}

EvalState evalState;

void Begin(SimulationManager@)
{
    VarsInit();

    steerMin = Math::Min(varSteerTowards, varSteerAway);
    steerMax = Math::Max(varSteerTowards, varSteerAway);

    steerDirection = GetSign(varSteerTowards - varSteerAway);
    switch (varSteerOffsetStrategy)
    {
    case SteerOffsetStrategy::OFF:
        refineSteerOffset = false;
        steerOffset = 0;
    break;
    case SteerOffsetStrategy::MANUAL:
        refineSteerOffset = false;
        steerOffset = varSteerOffset * steerDirection;
    break;
    case SteerOffsetStrategy::AUTOMATIC:
        SteerOffsetStrategyAutomaticInit();
    break;
    default:
        Unreachable();
    break;
    }

    maxSpeedLoss  = varMaxSpeedLoss  / 3.6;
    maxSpeedBleed = varMaxSpeedBleed / 3.6;

    switch (varLookaheadStrategy)
    {
    case LookaheadStrategy::ABSOLUTE:
        targetTime = varLookahead;
        timeout = varLookahead;
        @onStep = StaticStep;
    break;
    case LookaheadStrategy::RELATIVE:
        timeout = varTimeout;
        @onStep = StaticStep;
    break;
    case LookaheadStrategy::DYNAMIC:
        cacheHint = varMaxRollback > 0 ? varMaxRollback : 100;
        @onStep = DynamicStep;
    break;
    default:
        Unreachable();
    break;
    }
}

void Iteration(SimulationManager@)
{
    if (varLookaheadStrategy == LookaheadStrategy::DYNAMIC)
    {
        targetTime = varBaseLookahead;
        peakTime = 0;
    }

    evalState = EvalState::SEARCH;
}

void SteerOffsetStrategyAutomaticInit()
{
    refineSteerOffset = true;
    steerOffsetTowards = 0;
    steerOffsetAway = varMaxSteerOffset * steerDirection;
}

bool rewinding;

float velocityPrevious;
float velocityCurrent;
float velocityMinimumImmediate;
float velocityMinimumCumulative;
uint lastHasAnyLateralContactTime;

funcdef void OnStep(SimulationManager@ sim, const ms time);
OnStep@ onStep;

void Step(SimulationManager@ sim)
{
    do
    {
        rewinding = false;

        const ms time = IncTimeGetRelative(sim);

        const auto@ const dyna = sim.Dyna;
        velocityPrevious = dyna.RefStatePrevious.LinearSpeed.Length();
        velocityCurrent = dyna.RefStateCurrent.LinearSpeed.Length();
        velocityMinimumImmediate = velocityPrevious - maxSpeedBleed;
        if (time == 0)
        {
            lastHasAnyLateralContactTime = sim.SceneVehicleCar.LastHasAnyLateralContactTime;
            velocityMinimumCumulative = velocityCurrent - maxSpeedLoss;
        }
        else if (velocityCurrent > velocityPrevious)
        {
            velocityMinimumCumulative = velocityCurrent - maxSpeedLoss;
        }

        onStep(sim, time);
    } while (rewinding);
}

ms timeout;

void StaticStep(SimulationManager@ sim, const ms time)
{
    switch (evalState)
    {
    case EvalState::SEARCH:
        if (time == 0)
            IncInputSet(sim, InputType::Steer, varSteerTowards);

        {
            const Constraint constraint = ConstraintsCheck(sim);
            if (constraint != Constraint::NONE)
            {
                if (time < 20)
                {
                    ConstraintFailure(sim, constraint);
                    return;
                }

                if (varLookaheadStrategy == LookaheadStrategy::RELATIVE)
                    targetTime = time + varLookaheadOffset;

                RewindToScan(sim);
            }
            else if (time == timeout)
            {
                Forward(sim, varSteerTowards);
            }
        }
    break;
    case EvalState::SCAN:
        if (Scan(sim, time))
            Forward(sim, steerBest);
    break;
    default:
        Unreachable();
    break;
    }
}

ms peakTime;
int peakSteer;

void DynamicStep(SimulationManager@ sim, const ms time)
{
    switch (evalState)
    {
    case EvalState::SEARCH:
        {
            const Constraint constraint = ConstraintsCheck(sim);
            if (time == 0)
            {
                if (constraint != Constraint::NONE)
                {
                    ConstraintFailure(sim, constraint);
                    return;
                }

                IncInputSet(sim, InputType::Steer, varSteerTowards);
            }
            else if (constraint != Constraint::NONE)
            {
                RewindToScan(sim);
            }
            else if (time == targetTime)
            {
                DynamicForward(sim, varSteerTowards);
            }
        }
    break;
    case EvalState::SCAN:
        if (Scan(sim, time))
        {
            IncInputSet(sim, InputType::Steer, steerBest);
            evalState = EvalState::EVALUATE;
        }
    break;
    case EvalState::EVALUATE:
        {
            const Constraint constraint = ConstraintsCheck(sim);
            if (constraint != Constraint::NONE)
            {
                if (peakTime > targetTime)
                {
                    DynamicForward(sim, peakSteer);
                    break;
                }

                if (IncBackwardCheck() < 0)
                {
                    ConstraintFailure(sim, constraint);
                    return;
                }
                IncBackward(sim, 10, cacheHint);

                targetTime += 10;
                if (varMaxRollback > 0)
                {
                    const ms rollback = targetTime - varBaseLookahead;
                    if (rollback > varMaxRollback)
                    {
                        print("[SteerMax] Ran out of rollback space!", Severity::Error);
                        IncTerminate(sim);
                        return;
                    }
                }

                peakTime = targetTime;
                evalState = EvalState::SEARCH;
            }
            else if (time == targetTime)
            {
                DynamicForward(sim, steerBest);
            }
        }
    break;
    default:
        Unreachable();
    break;
    }
}

void DynamicForward(SimulationManager@ sim, const int value)
{
    if (Forward(sim, value))
        return;

    if (targetTime > varBaseLookahead)
    {
        targetTime -= 10;
        peakSteer = value;
    }
    else
    {
        peakTime = 0;
    }
}

bool Forward(SimulationManager@ sim, const int value)
{
    const bool iterating = IncForwardCheck() > 0;
    if (iterating)
    {
        if (refineSteerOffset)
        {
            steerOffsetAway = steerOffset;
            steerOffsetTowards = 0;
            RefineSteerOffset(sim);
            return true;
        }

        if (varSteerOffsetStrategy == SteerOffsetStrategy::AUTOMATIC)
            SteerOffsetStrategyAutomaticInit();
    }

    IncStageSet(InputType::Steer, value);
    IncForward(sim);
    evalState = EvalState::SEARCH;
    return iterating;
}

void RefineSteerOffset(SimulationManager@ sim)
{
    const int min = Math::Min(steerOffsetTowards, steerOffsetAway);
    const int max = Math::Max(steerOffsetTowards, steerOffsetAway);

    const uint diff = max - min;
    if (diff >= 2)
    {
        steerOffset = min + diff / 2;
    }
    else if (steerOffset != steerOffsetAway)
    {
        steerOffset = steerOffsetAway;
        refineSteerOffset = false;
    }
    else
    {
        return;
    }

    IncRevert(sim);
}

int steerTowards;
int steerAway;

void RewindToScan(SimulationManager@ sim)
{
    steerTowards = varSteerTowards;
    steerAway    = varSteerAway;

    Rewind(sim);
    evalState = EvalState::SCAN;
}

int steer;
int steerBest;

bool Scan(SimulationManager@ sim, const ms time)
{
    if (time == 0)
    {
        const int min = Math::Min(steerTowards, steerAway);
        const int max = Math::Max(steerTowards, steerAway);

        const uint diff = max - min;
        if (diff < 2)
        {
            steerBest = Math::Clamp(steerAway - steerOffset, steerMin, steerMax);
            return true;
        }

        steer = min + diff / 2;
        IncInputSet(sim, InputType::Steer, steer);
    }
    else if (ConstraintsCheck(sim) != Constraint::NONE)
    {
        steerTowards = steer;
        Rewind(sim);
    }
    else if (time == targetTime)
    {
        steerAway = steer;
        steerTowards = varSteerTowards;
        Rewind(sim);
    }

    return false;
}

void Rewind(SimulationManager@ sim)
{
    IncRewindPreserve(sim);
    rewinding = true;
}

enum Constraint
{
    NONE,

    SPEED_LOSS,
    SPEED_BLEED,
    WALLBANG,
    SLIDE,
    SLIDING_WHEELS,
}

uint slidingWheels;

Constraint ConstraintsCheck(SimulationManager@ sim)
{
    if (velocityCurrent < velocityMinimumCumulative)
        return Constraint::SPEED_LOSS;

    const auto@ const svc = sim.SceneVehicleCar;

    if (velocityCurrent < velocityMinimumImmediate)
    {
        if (!varIgnoreGearingBleed || svc.GearboxState == 0)
            return Constraint::SPEED_BLEED;
    }

    if (varNoWallbang)
    {
        // The bool version does not always go to true despite a collision, yet the time still updates.
        if (svc.HasAnyLateralContact || svc.LastHasAnyLateralContactTime != lastHasAnyLateralContactTime)
            return Constraint::WALLBANG;
    }

    if (varNoSlide)
    {
        if (svc.IsSliding)
            return Constraint::SLIDE;
    }

    slidingWheels = 0;
    const auto@ const wheels = sim.Wheels;
    for (uint i = 0; i < 4; ++i)
        slidingWheels += wheels[i].RTState.IsSliding ? 1 : 0;

    if (slidingWheels < varSlidingWheelsMin || slidingWheels > varSlidingWheelsMax)
        return Constraint::SLIDING_WHEELS;

    return Constraint::NONE;
}

void ConstraintFailure(SimulationManager@ sim, const Constraint constraint)
{
    if (refineSteerOffset)
    {
        steerOffsetTowards = steerOffset;
        RefineSteerOffset(sim);
        return;
    }

    string s;
    s += "[SteerMax] Constraints could not be avoided: ";
    switch (constraint)
    {
    case Constraint::SPEED_LOSS:
        s += "Speed Loss: ";
        s += (velocityMinimumCumulative + maxSpeedLoss) - velocityCurrent;
        s += " exceeds ";
        s += maxSpeedLoss;
        s += " (m/s)";
    break;
    case Constraint::SPEED_BLEED:
        s += "Speed Bleed: ";
        s += (velocityMinimumImmediate + maxSpeedBleed) - velocityCurrent;
        s += " exceeds ";
        s += maxSpeedBleed;
        s += " (m/s)";
    break;
    case Constraint::WALLBANG:
        s += "Wallbang";
    break;
    case Constraint::SLIDE:
        s += "Slide";
    break;
    case Constraint::SLIDING_WHEELS:
        s += "Sliding Wheels: ";
        s += slidingWheels;
        s += " outside of [";
        s += varSlidingWheelsMin;
        s += ", ";
        s += varSlidingWheelsMax;
        s += "]";
    break;
    default:
        Unreachable();
    break;
    }
    print(s, Severity::Error);

    IncTerminate(sim);
}


} // namespace SteerMax
