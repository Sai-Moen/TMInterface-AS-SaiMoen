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
    @mode.end = End;
    IncRegisterMode("SteerMax", mode);
}

const string VAR = ::Core::VAR + "sm_";

const string VAR_TIMEOUT       = VAR + "timeout";
const string VAR_LOOKAHEAD     = VAR + "lookahead";
const string VAR_INITIAL_STEER = VAR + "initial_steer";
const string VAR_STEER_OFFSET  = VAR + "steer_offset";

const string VAR_MAX_SPEED_BLEED = VAR + "max_speed_bleed";
const string VAR_MAX_SPEED_LOSS  = VAR + "max_speed_loss";
const string VAR_NO_WALLBANG     = VAR + "no_wallbang";
const string VAR_NO_SLIDE        = VAR + "no_slide";

ms varTimeout;
ms varLookahead;
int varInitialSteer;
int varSteerOffset;

float varMaxSpeedBleed;
float varMaxSpeedLoss;
bool varNoWallbang;
bool varNoSlide;

void Register()
{
    RegisterVariable(VAR_TIMEOUT, 200);
    RegisterVariable(VAR_LOOKAHEAD, 200);
    RegisterVariable(VAR_INITIAL_STEER, 0x10000);
    RegisterVariable(VAR_STEER_OFFSET, 0);

    RegisterVariable(VAR_MAX_SPEED_BLEED, 0.1);
    RegisterVariable(VAR_MAX_SPEED_LOSS, 36);
    RegisterVariable(VAR_NO_WALLBANG, true);
    RegisterVariable(VAR_NO_SLIDE, true);

    varTimeout = VarGetMs(VAR_TIMEOUT);
    varLookahead = VarGetMs(VAR_LOOKAHEAD);
    varInitialSteer = VarGetInt(VAR_INITIAL_STEER);
    varSteerOffset = VarGetInt(VAR_STEER_OFFSET);

    varMaxSpeedBleed = VarGetFloat(VAR_MAX_SPEED_BLEED);
    varMaxSpeedLoss = VarGetFloat(VAR_MAX_SPEED_LOSS);
    varNoWallbang = VarGetBool(VAR_NO_WALLBANG);
    varNoSlide = VarGetBool(VAR_NO_SLIDE);
}

void Draw()
{
    varTimeout = UI::InputTimeVar("Timeout", VAR_TIMEOUT, 10);
    // TODO: tooltip

    varLookahead = UI::InputTimeVar("Lookahead", VAR_LOOKAHEAD, 10);
    // TODO: tooltip

    varInitialSteer = UI::SliderInt("Initial Steer", varInitialSteer, STEER_MIN, STEER_MAX);
    // TODO: tooltip

    if (UI::Button("Left"))
        varInitialSteer = STEER_MIN;
    UI::SameLine();
    if (UI::Button("Right"))
        varInitialSteer = STEER_MAX;

    varInitialSteer = ClampSteer(varInitialSteer);
    if (varInitialSteer == 0)
        varInitialSteer = 1;
    VarSetInt(VAR_INITIAL_STEER, varInitialSteer);

    varSteerOffset = UI::InputInt("Steer Offset", varSteerOffset);
    // TODO: tooltip

    if (varSteerOffset < 0)
        varSteerOffset = 0;
    VarSetInt(VAR_STEER_OFFSET, varSteerOffset);

    varMaxSpeedBleed = UI::InputFloatVar("Max Speed Bleed", VAR_MAX_SPEED_BLEED);
    // TODO: tooltip

    varMaxSpeedLoss = UI::InputFloatVar("Max Speed Loss", VAR_MAX_SPEED_LOSS);
    // TODO: tooltip

    varNoWallbang = UI::CheckboxVar("No wallbang", VAR_NO_WALLBANG);
    // TODO: tooltip

    varNoSlide = UI::CheckboxVar("No slide", VAR_NO_SLIDE);
    // TODO: tooltip
}

// Amount of time it takes for an input to change the state of the car.
const ms CAUSALITY = 20;

int initialSteerTowards;
int initialSteerAway;
int steerOffset;

float maxSpeedBleed;
float maxSpeedLoss;

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

    const int clampedInitialSteer = ClampSteer(varInitialSteer);
    if (varInitialSteer != clampedInitialSteer)
    {
        varInitialSteer = clampedInitialSteer;
        VarSetInt(VAR_INITIAL_STEER, varInitialSteer);
    }
    initialSteerTowards = varInitialSteer;
    initialSteerAway = -varInitialSteer;

    steerOffset = varSteerOffset * GetSign(clampedInitialSteer);

    maxSpeedBleed = varMaxSpeedBleed / 3.6;
    maxSpeedLoss = varMaxSpeedLoss / 3.6;

    Reset();
}

enum StepState
{
    SEARCH,
    SCAN,
    EVALUATE,
}

StepState stepState;

uint lastHasAnyLateralContactTime;
float velocityPrevious;
float velocityCurrent;
float velocityMinimumImmediate;
float velocityMinimumCumulative;

int collider;
int steer;
int avoider;

void Step(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(sim);

    const auto@ const dyna = sim.Dyna;
    velocityPrevious = dyna.RefStatePrevious.LinearSpeed.Length();
    velocityCurrent = dyna.RefStateCurrent.LinearSpeed.Length();
    velocityMinimumImmediate = velocityPrevious - maxSpeedBleed;

    switch (stepState)
    {
    // Phase 1: Search - Find the earliest tInput on which the constraints are violated for initialSteer within 'timeout' ms.
    //                   (also grab some information).
    case StepState::SEARCH:
        if (time == 0)
        {
            lastHasAnyLateralContactTime = sim.SceneVehicleCar.LastHasAnyLateralContactTime;
            velocityMinimumCumulative = velocityCurrent - maxSpeedLoss;

            if (ConstraintsViolated(sim))
                print("[SteerMax] Constraints already violated at input time...", Severity::Warning);

            IncInputSet(sim, InputType::Steer, initialSteerTowards);
        }
        else if (ConstraintsViolated(sim))
        {
            IncRewindPreserve(sim);
            stepState = StepState::SCAN;
            Step(sim);
        }
        else if (time == varTimeout)
        {
            IncCommitContext ctx;
            ctx.Set(InputType::Steer, initialSteerTowards);
            IncCommit(sim, ctx);
        }
    break;
    // Phase 2: Scan - Find the latest tick on which countersteering removes the constraint violations within 'lookahead' ms
    //                 (starting from the countersteer tick, or maybe the constraint violation tick?).
    case StepState::SCAN:
        // TODO
    break;
    // Phase 3: Evaluate - Binary search for 'maximal' steering value on this tick, that does not violate the constraints.
    case StepState::EVALUATE:
        // TODO
    break;
    default:
        Unreachable();
    break;
    }
}

void End(SimulationManager@)
{
    stepState = StepState::SEARCH;
}

void Reset()
{
    collider = initialSteerTowards;
    avoider = initialSteerAway;

    stepState = StepState::SEARCH;
}

bool ConstraintsViolated(SimulationManager@ sim)
{
    if (velocityCurrent < velocityPrevious)
    {
        if (velocityCurrent < velocityMinimumImmediate || velocityCurrent < velocityMinimumCumulative)
            return true;
    }
    else
    {
        // Velocity no longer dropping: set new minimum.
        velocityMinimumCumulative = velocityCurrent - maxSpeedLoss;
    }

    const auto@ const svc = sim.SceneVehicleCar;

    if (varNoWallbang)
    {
        if (svc.HasAnyLateralContact || svc.LastHasAnyLateralContactTime != lastHasAnyLateralContactTime)
            return true;
    }

    if (varNoSlide)
    {
        // Ask Dona to also add the timed slide fields,
        // maybe this field has the same issue where the bool does not always go to true...
        if (svc.IsSliding)
            return true;
    }

    return false;
}


} // namespace SteerMax
