namespace SteerMax
{


void Main()
{
    Register();

    IncMode mode;
    mode.preservationExclusions = { InputType::Left, InputType::Right, InputType::Steer };
    @mode.draw = Draw;
    @mode.begin = Begin;
    @mode.step = Step;
    IncRegisterMode("SteerMax", mode);
}

const string VAR = ::Core::VAR + "sm_";

const string VAR_TIMEOUT       = VAR + "timeout";
const string VAR_LOOKAHEAD     = VAR + "lookahead";
const string VAR_STEER_TOWARDS = VAR + "steer_towards";
const string VAR_STEER_AWAY    = VAR + "steer_away";
const string VAR_STEER_OFFSET  = VAR + "steer_offset";

const string VAR_MAX_SPEED_LOSS  = VAR + "max_speed_loss";
const string VAR_MAX_SPEED_BLEED = VAR + "max_speed_bleed";
const string VAR_NO_WALLBANG     = VAR + "no_wallbang";
const string VAR_NO_SLIDE        = VAR + "no_slide";

ms varTimeout;
ms varLookahead;
int varSteerTowards;
int varSteerAway;
int varSteerOffset;

float varMaxSpeedLoss;
float varMaxSpeedBleed;
bool varNoWallbang;
bool varNoSlide;

void Register()
{
    RegisterVariable(VAR_TIMEOUT, 200);
    RegisterVariable(VAR_LOOKAHEAD, 200);
    RegisterVariable(VAR_STEER_TOWARDS, STEER_MAX);
    RegisterVariable(VAR_STEER_AWAY, STEER_MIN);
    RegisterVariable(VAR_STEER_OFFSET, 0);

    RegisterVariable(VAR_MAX_SPEED_LOSS, 36);
    RegisterVariable(VAR_MAX_SPEED_BLEED, 0.1);
    RegisterVariable(VAR_NO_WALLBANG, true);
    RegisterVariable(VAR_NO_SLIDE, true);

    varTimeout      = VarGetMs(VAR_TIMEOUT);
    varLookahead    = VarGetMs(VAR_LOOKAHEAD);
    varSteerTowards = VarGetInt(VAR_STEER_TOWARDS);
    varSteerAway    = VarGetInt(VAR_STEER_AWAY);
    varSteerOffset  = VarGetInt(VAR_STEER_OFFSET);

    varMaxSpeedLoss  = VarGetFloat(VAR_MAX_SPEED_LOSS);
    varMaxSpeedBleed = VarGetFloat(VAR_MAX_SPEED_BLEED);
    varNoWallbang    = VarGetBool(VAR_NO_WALLBANG);
    varNoSlide       = VarGetBool(VAR_NO_SLIDE);
}

void Draw()
{
    varTimeout = UI::InputTimeVar("Timeout", VAR_TIMEOUT, 10);
    // TODO: tooltip

    varLookahead = UI::InputTimeVar("Lookahead", VAR_LOOKAHEAD, 10);
    // TODO: tooltip

    varSteerTowards = UI::SliderInt("Steer Towards", varSteerTowards, STEER_MIN, STEER_MAX);
    // TODO: tooltip

    varSteerAway = UI::SliderInt("Steer Away", varSteerAway, STEER_MIN, STEER_MAX);
    // TODO: tooltip

    const bool left = UI::Button("Left");
    UI::SameLine();
    const bool right = UI::Button("Right");

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
        if (varSteerTowards == varSteerAway)
        {
            ++varSteerTowards;
            --varSteerAway;
        }

        varSteerTowards = ClampSteer(varSteerTowards);
        varSteerAway    = ClampSteer(varSteerAway);
    }
    VarSetInt(VAR_STEER_TOWARDS, varSteerTowards);
    VarSetInt(VAR_STEER_AWAY,    varSteerAway);

    varSteerOffset = UI::InputInt("Steer Offset", varSteerOffset);
    // TODO: tooltip

    if (varSteerOffset < 0)
        varSteerOffset = 0;
    VarSetInt(VAR_STEER_OFFSET, varSteerOffset);

    UI::Separator();

    varMaxSpeedLoss = UI::InputFloatVar("Max Speed Loss", VAR_MAX_SPEED_LOSS);
    // TODO: tooltip

    varMaxSpeedBleed = UI::InputFloatVar("Max Speed Bleed", VAR_MAX_SPEED_BLEED);
    // TODO: tooltip

    varNoWallbang = UI::CheckboxVar("No Wallbang", VAR_NO_WALLBANG);
    // TODO: tooltip

    varNoSlide = UI::CheckboxVar("No Slide", VAR_NO_SLIDE);
    // TODO: tooltip
}

// Amount of time it takes for an input to change the state of the car.
const ms CAUSALITY = 20;

int steerOffset;
float maxSpeedLoss;
float maxSpeedBleed;

int initialSteer;
int initialSteerStep;

enum StepState
{
    // Find the earliest tInput on which the constraints are violated for initialSteer within 'timeout' ms.
    // (also grab some information).
    SEARCH,

    // Find the latest tick on which countersteering removes the constraint violations within 'lookahead' ms
    // (starting from the countersteer tick, or maybe the constraint violation tick?).
    SCAN,

    // Binary search for 'maximal' steering value on this tick, that does not violate the constraints.
    EVALUATE,
}

StepState stepState;

void Begin(SimulationManager@)
{
    if (varTimeout < CAUSALITY)
    {
        varTimeout = CAUSALITY;
        VarSetMs(VAR_TIMEOUT, varTimeout);
    }

    if (varLookahead < CAUSALITY)
    {
        varLookahead = CAUSALITY;
        VarSetMs(VAR_LOOKAHEAD, varLookahead);
    }

    const int clampedSteerTowards = ClampSteer(varSteerTowards);
    if (varSteerTowards != clampedSteerTowards)
    {
        varSteerTowards = clampedSteerTowards;
        VarSetInt(VAR_STEER_TOWARDS, varSteerTowards);
    }

    const int clampedSteerAway = ClampSteer(varSteerAway);
    if (varSteerAway != clampedSteerAway)
    {
        varSteerAway = clampedSteerAway;
        VarSetInt(VAR_STEER_AWAY, varSteerAway);
    }

    const int min = Math::Min(varSteerTowards, varSteerAway);
    const int max = Math::Max(varSteerTowards, varSteerAway);

    initialSteer     = min + (max - min) / 2;
    initialSteerStep = (varSteerAway - varSteerTowards) / 2;

    steerOffset      = varSteerOffset * GetSign(varSteerAway - varSteerTowards);
    maxSpeedLoss  = varMaxSpeedLoss  / 3.6;
    maxSpeedBleed = varMaxSpeedBleed / 3.6;

    stepState = StepState::SEARCH;
}

uint lastHasAnyLateralContactTime;
float velocityPrevious;
float velocityCurrent;
float velocityMinimumImmediate;
float velocityMinimumCumulative;

enum Constraint
{
    NONE,

    SPEED_LOSS,
    SPEED_BLEED,
    WALLBANG,
    SLIDE,
}

String@ GenerateConstraintFailureMessage(const Constraint c)
{
    string message;
    switch (c)
    {
    case Constraint::NONE:
        return String();
    case Constraint::SPEED_LOSS:
        message += "Speed Loss: ";
        message += (velocityMinimumCumulative + maxSpeedLoss) - velocityCurrent;
        message += " exceeds ";
        message += maxSpeedLoss;
        message += " (m/s)";
    break;
    case Constraint::SPEED_BLEED:
        message += "Speed Bleed: ";
        message += (velocityMinimumImmediate + maxSpeedBleed) - velocityCurrent;
        message += " exceeds ";
        message += maxSpeedBleed;
        message += " (m/s)";
    break;
    case Constraint::WALLBANG:
        message = "Wallbang";
    break;
    case Constraint::SLIDE:
        message = "Slide";
    break;
    default:
        Unreachable();
    break;
    }
    return message;
}

ms steerAwayTime;
ms targetTime;

int steer;
int steerStep;
int steerTowards;
int steerAway;

void Step(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(sim);

    const auto@ const dyna = sim.Dyna;
    velocityPrevious = dyna.RefStatePrevious.LinearSpeed.Length();
    velocityCurrent = dyna.RefStateCurrent.LinearSpeed.Length();
    velocityMinimumImmediate = velocityPrevious - maxSpeedBleed;

    switch (stepState)
    {
    case StepState::SEARCH:
        if (time == 0)
        {
            lastHasAnyLateralContactTime = sim.SceneVehicleCar.LastHasAnyLateralContactTime;
            velocityMinimumCumulative = velocityCurrent - maxSpeedLoss;

            const Constraint c = ConstraintsCheck(sim);
            if (c != Constraint::NONE)
            {
                string s;
                s += "[SteerMax] Constraints already violated at input time: ";
                s += GenerateConstraintFailureMessage(c);
                print(s, Severity::Error);
                IncTerminate();
                break;
            }

            IncInputSet(sim, InputType::Steer, varSteerTowards);
            break;
        }

        {
            const Constraint c = ConstraintsCheck(sim);
            if (c != Constraint::NONE)
            {
                steerAwayTime = time - CAUSALITY;
                targetTime = time + varLookahead;
                if (steerAwayTime < 0)
                {
                    string s;
                    s += "[SteerMax] Contraints violated before they can be avoided: ";
                    s += GenerateConstraintFailureMessage(c);
                    print(s, Severity::Error);
                    IncTerminate();
                    break;
                }

                stepState = StepState::SCAN;
                IncRewindPreserve(sim);
                Step(sim);
            }
            else if (time == varTimeout)
            {
                IncCommitContext ctx;
                ctx.Set(InputType::Steer, varSteerTowards);
                IncCommit(sim, ctx);
            }
        }
    break;
    case StepState::SCAN:
        if (time == steerAwayTime)
        {
            IncInputSet(sim, InputType::Steer, varSteerAway);
            break;
        }

        if (steerAwayTime >= 10)
        {
            if (ConstraintsCheck(sim) != Constraint::NONE)
            {
                steerAwayTime -= 10;
                IncRewindPreserve(sim);
                Step(sim);
                break;
            }

            IncAssert(time <= targetTime);
            if (time != targetTime)
                break;
        }

        steer        = initialSteer;
        steerStep    = initialSteerStep;
        steerTowards = varSteerTowards;
        steerAway    = varSteerAway;

        stepState = StepState::EVALUATE;
        if (steerAwayTime >= 10)
        {
            IncCommitContext ctx;
            ctx.Advance = steerAwayTime;
            ctx.Set(InputType::Steer, varSteerTowards);
            IncCommit(sim, ctx);
        }
        else
        {
            IncRewindRemove(sim);
            Step(sim);
        }
    break;
    case StepState::EVALUATE:
        if (time == 0)
        {
            IncInputSet(sim, InputType::Steer, steer);
            break;
        }

        {
            const Constraint constraint = ConstraintsCheck(sim);
            const bool lastStep = Math::Abs(steerStep) == 1;

            if (constraint != Constraint::NONE)
            {
                if (lastStep)
                {
                    SteerNextStep(sim);
                    break;
                }

                steerTowards = steer;
                steer += steerStep;
                if (steer <= varSteerTowards && steer <= steerAway || steer >= varSteerTowards && steer >= steerAway)
                {
                    SteerNextStep(sim);
                    break;
                }
            }

            if (time == targetTime)
            {
                const bool inbounds =
                    steer <= varSteerTowards && steer > steerAway ||
                    steer >= varSteerTowards && steer < steerAway;
                if (constraint == Constraint::NONE && inbounds)
                {
                    steerAway = steer;
                    if (lastStep)
                    {
                        steer += steerStep;
                        IncRewindPreserve(sim);
                        Step(sim);
                        break;
                    }
                }
                SteerNextStep(sim);
            }
        }
    break;
    default:
        Unreachable();
    break;
    }
}

Constraint ConstraintsCheck(SimulationManager@ sim)
{
    if (velocityCurrent < velocityPrevious)
    {
        if (velocityCurrent < velocityMinimumCumulative)
            return Constraint::SPEED_LOSS;

        if (velocityCurrent < velocityMinimumImmediate)
            return Constraint::SPEED_BLEED;
    }
    else
    {
        // Velocity no longer dropping: set new minimum.
        velocityMinimumCumulative = velocityCurrent - maxSpeedLoss;
    }

    const auto@ const svc = sim.SceneVehicleCar;

    if (varNoWallbang)
    {
        // The bool version does not always go to true despite a collision, yet the time still updates.
        // Unfortunately I cannot find the replay in which this happened anymore...
        if (svc.HasAnyLateralContact || svc.LastHasAnyLateralContactTime != lastHasAnyLateralContactTime)
            return Constraint::WALLBANG;
    }

    if (varNoSlide)
    {
        // Ask Dona to also add the timed slide fields,
        // maybe this field has the same issue where the bool does not always go to true...
        if (svc.IsSliding)
            return Constraint::SLIDE;
    }

    return Constraint::NONE;
}

void SteerNextStep(SimulationManager@ sim)
{
    steerStep /= 2;
    switch (Math::Abs(steerStep))
    {
    case 0:
        stepState = StepState::SEARCH;

        {
            IncCommitContext ctx;
            ctx.Set(InputType::Steer, steerAway);
            IncCommit(sim, ctx);
        }

        return;
    case 1:
        steer = steerAway;
    break;
    default:
        steer = steerTowards - steerStep / 2;
    break;
    }

    IncRewindPreserve(sim);
    Step(sim);
}


} // namespace SteerMax
