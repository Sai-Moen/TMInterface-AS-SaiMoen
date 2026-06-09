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
    @mode.step = Step;
    IncModeRegister("SteerMax", mode);
}

const string VAR = ::Core::VAR + "sm_";

const string VAR_TIMEOUT       = VAR + "timeout";
const string VAR_LOOKAHEAD     = VAR + "lookahead";
const string VAR_STEER_TOWARDS = VAR + "steer_towards";
const string VAR_STEER_AWAY    = VAR + "steer_away";
const string VAR_STEER_OFFSET  = VAR + "steer_offset";

const string VAR_MAX_SPEED_LOSS       = VAR + "max_speed_loss";
const string VAR_MAX_SPEED_BLEED      = VAR + "max_speed_bleed";
const string VAR_IGNORE_GEARING_BLEED = VAR + "ignore_gearing_bleed";

const string VAR_NO_WALLBANG = VAR + "no_wallbang";

const string VAR_NO_SLIDE           = VAR + "no_slide";
const string VAR_SLIDING_WHEELS_MIN = VAR + "sliding_wheels_min";
const string VAR_SLIDING_WHEELS_MAX = VAR + "sliding_wheels_max";

void VarsRegister()
{
    RegisterVariable(VAR_TIMEOUT,       200);
    RegisterVariable(VAR_LOOKAHEAD,     200);
    RegisterVariable(VAR_STEER_TOWARDS, STEER_MAX);
    RegisterVariable(VAR_STEER_AWAY,    STEER_MIN);
    RegisterVariable(VAR_STEER_OFFSET,  800);

    RegisterVariable(VAR_MAX_SPEED_LOSS,       18);
    RegisterVariable(VAR_MAX_SPEED_BLEED,      0.18);
    RegisterVariable(VAR_IGNORE_GEARING_BLEED, true);

    RegisterVariable(VAR_NO_WALLBANG, true);

    RegisterVariable(VAR_NO_SLIDE,           false);
    RegisterVariable(VAR_SLIDING_WHEELS_MIN, 0);
    RegisterVariable(VAR_SLIDING_WHEELS_MAX, 0);
}

ms varTimeout;
ms varLookahead;
int varSteerTowards;
int varSteerAway;
int varSteerOffset;

float varMaxSpeedLoss;
float varMaxSpeedBleed;
bool varIgnoreGearingBleed;

bool varNoWallbang;

bool varNoSlide;
uint varSlidingWheelsMin;
uint varSlidingWheelsMax;

void VarsInit()
{
    varTimeout = VarGetTime(VAR_TIMEOUT);
    if (varTimeout < 0)
    {
        varTimeout = 0;
        VarSetTime(VAR_TIMEOUT, varTimeout);
    }

    varLookahead = VarGetTime(VAR_LOOKAHEAD);
    if (varLookahead < 0)
    {
        varLookahead = 0;
        VarSetTime(VAR_LOOKAHEAD, varLookahead);
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

    varSteerOffset = VarGetInt(VAR_STEER_OFFSET);
    if (varSteerOffset < 0)
    {
        varSteerOffset = 0;
        VarSetInt(VAR_STEER_OFFSET, varSteerOffset);
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
    varTimeout = UI::InputTimeVar("Timeout", VAR_TIMEOUT, 10);
    TooltipOnHover("If the constraints hold for this amount of time, use maximum steering and go to the next tick.");

    varLookahead = UI::InputTimeVar("Lookahead", VAR_LOOKAHEAD, 10);
    TooltipOnHover(
        "If the constraints did not hold, look ahead from the constraint failure time by this amount of time.\n"
        "A new steering value will then be determined which does not fail before the lookahead.");

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

    varSteerOffset = UI::InputInt("Steer Offset", varSteerOffset);
    if (varSteerOffset < 0)
        varSteerOffset = 0;
    VarSetInt(VAR_STEER_OFFSET, varSteerOffset);
    TooltipOnHover(
        "After determining a new steering value, offset it (up to) the given offset away.\n"
        "Where 'away' means less maximal steering, i.e. Steer Away.\n"
        "This will respect the steering bounds specified above, hence it may not be able to offset by the requested amount.");

    UI::Separator();
    UI::Text("Constraints");

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

    varNoSlide = UI::CheckboxVar("No Slide", VAR_NO_SLIDE);
    TooltipOnHover(
        "Enabling this will count any sliding as an immediate failure.\n"
        "NOTE: this property checks the car's sliding state, which will very quickly report the car as sliding,"
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

int steerMin;
int steerMax;

int steerOffset;
float maxSpeedLoss;
float maxSpeedBleed;

enum EvalState
{
    NONE,

    SEARCH,
    EVALUATE,
}

EvalState evalState;

void Begin(SimulationManager@)
{
    VarsInit();

    steerMin = Math::Min(varSteerTowards, varSteerAway);
    steerMax = Math::Max(varSteerTowards, varSteerAway);

    steerOffset   = varSteerOffset * GetSign(varSteerAway - varSteerTowards);
    maxSpeedLoss  = varMaxSpeedLoss  / 3.6;
    maxSpeedBleed = varMaxSpeedBleed / 3.6;

    evalState = EvalState::SEARCH;
}

float velocityPrevious;
float velocityCurrent;
float velocityMinimumImmediate;
float velocityMinimumCumulative;
uint lastHasAnyLateralContactTime;

enum Constraint
{
    NONE,

    SPEED_LOSS,
    SPEED_BLEED,
    WALLBANG,
    SLIDE,
    SLIDING_WHEELS,
}

string GenerateConstraintFailureMessage(const Constraint constraint)
{
    string s;
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
        s = "Wallbang";
    break;
    case Constraint::SLIDE:
        s = "Slide";
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
    return s;
}

ms targetTime;

int steer;
int steerTowards;
int steerAway;

bool rewinding;

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
        if (time == 0 || velocityCurrent > velocityPrevious)
            velocityMinimumCumulative = velocityCurrent - maxSpeedLoss;

        switch (evalState)
        {
        case EvalState::SEARCH:
            if (time == 0)
            {
                lastHasAnyLateralContactTime = sim.SceneVehicleCar.LastHasAnyLateralContactTime;

                const Constraint constraint = ConstraintsCheck(sim);
                if (constraint != Constraint::NONE)
                {
                    string s;
                    s += "[SteerMax] Constraints already violated at input time: ";
                    s += GenerateConstraintFailureMessage(constraint);
                    print(s, Severity::Error);

                    IncTerminate(sim);
                    return;
                }

                IncInputSet(sim, InputType::Steer, varSteerTowards);
            }
            else if (ConstraintsCheck(sim) != Constraint::NONE)
            {
                targetTime = time + varLookahead;

                steerTowards = varSteerTowards;
                steerAway    = varSteerAway;

                evalState = EvalState::EVALUATE;
                Rewind(sim);
            }
            else if (time == varTimeout)
            {
                IncStageSet(InputType::Steer, varSteerTowards);
                IncForwards(sim);
            }
        break;
        case EvalState::EVALUATE:
            if (time == 0)
            {
                const int min = Math::Min(steerTowards, steerAway);
                const int max = Math::Max(steerTowards, steerAway);

                const int diff = max - min;
                if (diff >= 2)
                {
                    steer = min + diff / 2;
                    IncInputSet(sim, InputType::Steer, steer);
                }
                else
                {
                    evalState = EvalState::SEARCH;

                    const int best = Math::Clamp(steerAway + steerOffset, steerMin, steerMax);
                    IncStageSet(InputType::Steer, best);
                    IncForwards(sim);
                }
            }
            else if (ConstraintsCheck(sim) != Constraint::NONE)
            {
                steerTowards = steer;
                Rewind(sim);
            }
            else if (time == targetTime)
            {
                steerAway = steer;

                // To try more steering values, we also reset steerTowards here.
                // This should not repeatedly test the same values,
                // as we stop resetting and commit when steerAway stops moving,
                // so we might do a couple duplicate attempts at the end in the worst case
                // (not enough to throw in an IntHashSet).
                steerTowards = varSteerTowards;
                Rewind(sim);
            }
        break;
        default:
            Unreachable();
        break;
        }
    } while (rewinding);
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

void Rewind(SimulationManager@ sim)
{
    IncRewindPreserve(sim);
    rewinding = true;
}


} // namespace SteerMax
