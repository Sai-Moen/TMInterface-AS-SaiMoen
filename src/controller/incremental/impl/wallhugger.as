namespace WH
{


const string NAME = "Wallhugger";
const string DESCRIPTION = "Hugs close to a given wall.";
const Mode@ const mode = Mode(
    NAME, DESCRIPTION,
    OnRegister, OnSettings,
    OnBegin, OnStep
);

const string PREFIX = ::PREFIX + "wh_";

const string MODE = PREFIX + "mode";

string modeStr;
array<string> modes;

const Mode@ whMode;
dictionary whMap;

void OnRegister()
{
    RegisterVariable(MODE, Classic::NAME);

    ModeRegister(whMap, Classic::mode);
    ModeRegister(whMap, Normal::mode);

    modeStr = GetVariableString(MODE);
    ModeDispatch(modeStr, whMap, whMode);

    modes = whMap.GetKeys();
    modes.SortAsc();
}

void OnSettings()
{
    if (ComboHelper("Wallhug Mode", modeStr, modes, ChangeMode))
    {
        DescribeModes("Wallhug Modes:", modes, whMap);
    }

    whMode.OnSettings();
}

void ChangeMode(const string &in newMode)
{
    ModeDispatch(newMode, whMap, whMode);
    SetVariable(MODE, newMode);
    modeStr = newMode;
}

void OnBegin(SimulationManager@ simManager)
{
    whMode.OnBegin(simManager);
}

void OnStep(SimulationManager@ simManager)
{
    whMode.OnStep(simManager);
}

int steer;

namespace Classic
{
    const string NAME = "Classic";
    const string DESCRIPTION = "The original wallhugger, ported to AngelScript.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PREFIX = WH::PREFIX + "classic_";

    const string SEEK      = PREFIX + "seek";
    const string DIRECTION = PREFIX + "direction";

    const ms DEFAULT_SEEK = 600;
    const float MAX_VEL_LOSS = 0.002; // per ms

    ms seek;

    enum Direction
    {
        left = -1,
        right = 1,
    }

    Direction direction;
    string directionStr;
    const array<string> directions = {"Left", "Right"};

    void OnRegister()
    {
        RegisterVariable(SEEK, DEFAULT_SEEK);
        RegisterVariable(DIRECTION, directions[0]);

        seek = ms(GetVariableDouble(SEEK));
        directionStr = GetVariableString(DIRECTION);
        direction = directions[0] == directionStr ? Direction::left : Direction::right;
    }

    void OnSettings()
    {
        seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
        ComboHelper("Direction", directionStr, directions, ChangeMode);
    }

    void ChangeMode(const string &in newMode)
    {
        direction = directions[0] == newMode ? Direction::left : Direction::right;
        directionStr = newMode;
    }

    float maxVelocityLoss;

    int avoider;
    int collider;

    void OnBegin(SimulationManager@)
    {
        maxVelocityLoss = seek * MAX_VEL_LOSS;
        Reset();
    }

    void OnStep(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsEvalTime(time))
        {
            OnEval(simManager);
            Eval::Rewind(simManager);
        }
        else
        {
            Eval::AddInput(simManager, time, InputType::Steer, steer);
        }
    }

    void OnEval(SimulationManager@ simManager)
    {
        const auto@ const svcNew = simManager.SceneVehicleCar;
        const auto@ const svcOld = Eval::MinState.SceneVehicleCar;

        const bool crashed =
            svcNew.LastHasAnyLateralContactTime != svcOld.LastHasAnyLateralContactTime ||
            svcNew.CurrentLocalSpeed.Length() < (svcOld.CurrentLocalSpeed.Length() - maxVelocityLoss);
        if (crashed)
            collider = steer;
        else
            avoider = steer;

        const bool isDone = Math::Abs(avoider - collider) <= 1;
        if (isDone)
        {
            Eval::Advance(simManager, avoider);
            Reset();
        }
        else
        {
            steer = (avoider + collider) >>> 1;
        }
    }

    void Reset()
    {
        Eval::Time::OffsetEval(seek);

        avoider = STEER::MIN * direction;
        collider = STEER::MAX * direction;
        steer = collider;
    }
}

namespace Normal
{
    const string NAME = "Normal";
    const string DESCRIPTION = "Uses the wall to determine how far to look ahead.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PREFIX = WH::PREFIX + "normal_";

    const string INITIAL_STEER = PREFIX + "initial_steer";
    int initialSteer;

    const string TIMEOUT = PREFIX + "timeout";
    const ms NO_TIMEOUT = 0;
    ms timeout;

    void OnRegister()
    {
        RegisterVariable(INITIAL_STEER, STEER::FULL);
        RegisterVariable(TIMEOUT, 2000);

        initialSteer = int(GetVariableDouble(INITIAL_STEER));
        timeout = ms(GetVariableDouble(TIMEOUT));
    }

    const string HELPFUL_TEXT = "Usually, you want to set this to " + STEER::MIN + " (left) or " + STEER::MAX + " (right).";

    void OnSettings()
    {
        if (UI::Button("Left"))
            initialSteer = STEER::MIN;
        UI::SameLine();
        initialSteer = UI::SliderInt("Initial Steer", initialSteer, STEER::MIN, STEER::MAX);
        UI::SameLine();
        if (UI::Button("Right"))
            initialSteer = STEER::MAX;

        initialSteer = ClampSteer(initialSteer);
        if (initialSteer == 0)
            initialSteer = 1;
        SetVariable(INITIAL_STEER, initialSteer);
        UI::TextWrapped(HELPFUL_TEXT);

        timeout = UI::InputTimeVar("Timeout", TIMEOUT);
        UI::TextWrapped("Timeout when looking for a wall (0 to disable)");
    }

    funcdef bool Oob(const int);

    bool hasTimeout;

    int bound;
    const Oob@ oob;

    void OnBegin(SimulationManager@)
    {
        hasTimeout = timeout != NO_TIMEOUT;

        switch (Sign(initialSteer))
        {
        case Signum::Negative:
            bound = STEER::MAX;
            @oob = function(nextSteer) { return nextSteer > bound; };
            break;
        case Signum::Zero:
            print("Initial Steer should not be 0...", Severity::Error);
            @onStep = null; // bit of trolling
            return;
        case Signum::Positive:
            bound = STEER::MIN;
            @oob = function(nextSteer) { return nextSteer < bound; };
            break;
        }

        Reset();
    }

    const OnSim@ onStep;
    
    void OnStep(SimulationManager@ simManager)
    {
        onStep(simManager);
    }

    void OnStepScan(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        const ms diff = time - Eval::Time::Input;
        if (simManager.SceneVehicleCar.HasAnyLateralContact)
        {
            const ms seek = diff + 100;
            Eval::Time::OffsetEval(seek);
            @onStep = OnStepMain;
        }
        else if (hasTimeout && diff >= timeout)
        {
            Advance(simManager, initialSteer);
        }
        else
        {
            Eval::AddInput(simManager, time, InputType::Steer, initialSteer);
            return;
        }

        Eval::Rewind(simManager);
    }

    void OnStepMain(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsEvalTime(time))
        {
            OnEval(simManager);
            Eval::Rewind(simManager);
        }
        else
        {
            Eval::AddInput(simManager, time, InputType::Steer, steer);
        }
    }

    int prevSteer;
    int step;

    void OnEval(SimulationManager@ simManager)
    {
        const int nextSteer = steer + step;
        if (oob(nextSteer))
        {
            prevSteer = steer;
            step >>>= 1;
        }
        else
        {
            const bool hasCrashed =
                simManager.SceneVehicleCar.LastHasAnyLateralContactTime !=
                Eval::MinState.SceneVehicleCar.LastHasAnyLateralContactTime;
            if (hasCrashed)
            {
                prevSteer = steer;
                steer = nextSteer;
            }
            else
            {
                step >>>= 1;
                if (step != 0)
                    steer = prevSteer;
            }
        }

        if (step == 0)
            Advance(simManager, steer);
    }

    void Advance(SimulationManager@ simManager, const int steer)
    {
        Eval::Advance(simManager, steer);
        Reset();
    }

    void Reset()
    {
        steer = initialSteer;
        prevSteer = steer;
        step = bound;

        @onStep = OnStepScan;
    }
}


} // namespace WH
