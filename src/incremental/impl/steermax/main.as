namespace SteerMax
{


void Main()
{
    RegisterSettings();
    IncRegisterMode("SteerMax", Mode());
}

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        varSeek = UI::InputTimeVar("Seek (lookahead) Time", VAR_SEEK, TICK);
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
        SetVariable(VAR_INITIAL_STEER, varInitialSteer);

        varMaxSpeedBleed = UI::InputFloatVar("Max Speed Bleed", VAR_MAX_SPEED_BLEED);
        // TODO: tooltip

        varMaxSpeedLoss = UI::InputFloatVar("Max Speed Loss", VAR_MAX_SPEED_LOSS);
        // TODO: tooltip

        varNoWallbang = UI::CheckboxVar("No wallbang", VAR_NO_WALLBANG);
        // TODO: tooltip

        varNoSlide = UI::CheckboxVar("No slide", VAR_NO_SLIDE);
        // TODO: tooltip
    }

    void OnBegin(SimulationManager@ sim)
    {
        IncRemoveSteeringAhead(sim);
        Init();
    }

    void OnStep(SimulationManager@ sim)
    {
        onStep(sim);
    }

    void OnEnd(SimulationManager@)
    {
        Deinit();
    }
}

const string VAR = Settings::VAR + "sm_";

const string VAR_SEEK = VAR + "seek";
const string VAR_INITIAL_STEER = VAR + "initial_steer";

const string VAR_MAX_SPEED_BLEED = VAR + "max_speed_bleed";
const string VAR_MAX_SPEED_LOSS = VAR + "max_speed_loss";
const string VAR_NO_WALLBANG = VAR + "no_wallbang";
const string VAR_NO_SLIDE = VAR + "no_slide";

ms varSeek;
int varInitialSteer;

float varMaxSpeedBleed;
float varMaxSpeedLoss;
bool varNoWallbang;
bool varNoSlide;

void RegisterSettings()
{
    RegisterVariable(VAR_SEEK, 600);
    RegisterVariable(VAR_INITIAL_STEER, 0x10000);

    RegisterVariable(VAR_MAX_SPEED_BLEED, 0.1);
    RegisterVariable(VAR_MAX_SPEED_LOSS, 36);
    RegisterVariable(VAR_NO_WALLBANG, true);
    RegisterVariable(VAR_NO_SLIDE, true);

    varSeek = GetConVarTime(VAR_SEEK);
    varInitialSteer = GetConVarInt(VAR_INITIAL_STEER);

    varMaxSpeedBleed = GetConVarFloat(VAR_MAX_SPEED_BLEED);
    varMaxSpeedLoss = GetConVarFloat(VAR_MAX_SPEED_LOSS);
    varNoWallbang = GetConVarBool(VAR_NO_WALLBANG);
    varNoSlide = GetConVarBool(VAR_NO_SLIDE);
}

// Amount of time it takes for an input to change the state of the car.
const ms CAUSALITY = TickToMs(2);

ms seek;
int initialSteerTowards;
int initalSteerAway;

float maxSpeedBleed;
float maxSpeedLoss;

// Initialize non-convars.
void Init()
{
    if (varSeek < CAUSALITY)
    {
        print("Seek too low: " + varSeek + "ms, setting to: " + CAUSALITY, Severity::Warning);
        varSeek = CAUSALITY;
        SetVariable(VAR_SEEK, varSeek);
    }
    seek = varSeek;

    int clampedInitialSteer = ClampSteer(varInitialSteer);
    if (clampedInitialSteer != varInitialSteer)
    {
        print("Initial Steer out of range: " + varInitialSteer + ", clamping to: " + clampedInitialSteer, Severity::Warning);
        varInitialSteer = clampedInitialSteer;
        SetVariable(VAR_INITIAL_STEER, varInitialSteer);
    }
    initialSteerTowards = varInitialSteer;
    initialSteerAway = -varInitialSteer;

    maxSpeedBleed = varMaxSpeedBleed / 3.6;
    maxSpeedLoss = varMaxSpeedLoss / 3.6;

    Reset();
}

// Destroy things ASAP if needed (large array or whatever).
void Deinit()
{
    // ...
}

int collider;
int avoider;

float previousSpeed;
float lastSpeedPeak;

// Per-iteration reset.
void Reset()
{
    collider = initialSteerTowards;
    avoider = initialSteerAway;

    @onStep = OnStepInit;
}

/*
Phases:
1. Search -- Find the earliest tInput on which the constraints are violated for initialSteer within 'seek' ms.
2. Scan -- Find the latest tick on which countersteering removes the constraint violations within 'seek' ms
    (starting from the countersteer tick).
3. Evaluate -- Binary search for 'maximal' steering value on this tick, that does not violate the constraints.

Notes:
Need an Incremental API to fast-forward/commit at a different time?
*/

funcdef void OnSim(SimulationManager@ sim);

OnSim@ onStep;

void OnStepSearch(SimulationManager@ sim)
{
    const ms time = IncGetRelativeTime(simManager);
    if (time == 0)
    {
        IncSetInput(sim, InputType::Steer, initialSteerTowards);
        return;
    }
    // TODO
}

bool ConstraintsHold(SimulationManager@ simManager)
{
    // TODO: speed bleed/loss
    const auto@ const svcOld = IncGetTrailingState().SceneVehicleCar;
    const auto@ const svcNew = simManager.SceneVehicleCar;

    if (varNoWallbang)
    {
        if (svcNew.HasAnyLateralContact || svcNew.LastHasAnyLateralContactTime != svcOld.LastHasAnyLateralContactTime)
            return false;
    }

    if (varNoSlide)
    {
        // Ask Dona to also add the timed slide fields,
        // maybe this field has the same issue where the bool does not always go to true...
        if (svcNew.IsSliding)
            return false;
    }

    return true;
}


}
