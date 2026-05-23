namespace SteerMax
{


IncMode mode;

void Main()
{
    Register();

    mode.preservationExclusions = { InputType::Left, InputType::Right, InputType::Steer };

    @mode.draw = Draw;
    @mode.begin = Begin;
    @mode.step = StepSearch;
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
    RegisterVariable(VAR_TIMEOUT, 1200);
    RegisterVariable(VAR_LOOKAHEAD, 600);
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

// Initialize non-convars.
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

void End(SimulationManager@)
{
    // Call Reset here or not?
    @mode.step = StepSearch;
}

int collider;
int avoider;

float previousSpeed;
float lastSpeedPeak;

void Reset()
{
    collider = initialSteerTowards;
    avoider = initialSteerAway;

    @mode.step = StepSearch;
}

// Phase 1: Search - Find the earliest tInput on which the constraints are violated for initialSteer within 'timeout' ms.
void StepSearch(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(sim);
    if (time == 0)
    {
        IncInputSet(sim, InputType::Steer, initialSteerTowards);
        return;
    }
    // TODO
}

// Phase 2: Scan -- Find the latest tick on which countersteering removes the constraint violations within 'lookahead' ms
//                  (starting from the countersteer tick).
void StepScan(SimulationManager@ sim)
{
    // TODO
}

// Phase 3: Evaluate -- Binary search for 'maximal' steering value on this tick, that does not violate the constraints.
void StepEvaluate(SimulationManager@ sim)
{
    // TODO
}

bool ConstraintsHold(SimulationManager@ sim)
{
    // TODO: grab information from svc ahead of time...
    return false; // TODO: just to compile, remove later and uncomment the rest.

    // // TODO: speed bleed/loss
    // const auto@ const svcOld = IncGetTrailingState().SceneVehicleCar;
    // const auto@ const svcNew = sim.SceneVehicleCar;

    // if (varNoWallbang)
    // {
    //     if (svcNew.HasAnyLateralContact || svcNew.LastHasAnyLateralContactTime != svcOld.LastHasAnyLateralContactTime)
    //         return false;
    // }

    // if (varNoSlide)
    // {
    //     // Ask Dona to also add the timed slide fields,
    //     // maybe this field has the same issue where the bool does not always go to true...
    //     if (svcNew.IsSliding)
    //         return false;
    // }

    // return true;
}


} // namespace SteerMax
