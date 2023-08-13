// Wallhugger Script

namespace WH
{
    const string NAME = "Wallhugger";
    const string DESCRIPTION = "Hugs close to a given wall.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("wh_" + var);
    }

    const string MODE = PrefixVar("mode");

    string modeStr;
    array<string> modes;

    const Mode@ whMode;
    dictionary whMap;

    void OnRegister()
    {
        RegisterVariable(MODE, Classic::NAME);

        ModeRegister(whMap, Classic::mode);

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
}

namespace WH::Classic
{
    const string NAME = "Classic";
    const string DESCRIPTION = "The original wallhugger, ported to AngelScript.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PrefixVar(const string &in var)
    {
        return WH::PrefixVar("classic_" + var);
    }

    const string SEEK = PrefixVar("seek");
    const string DIRECTION = PrefixVar("direction");

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
    bool isDone;

    int avoider;
    int collider;
    int steer;

    void OnBegin(SimulationManager@ simManager)
    {
        maxVelocityLoss = seek * MAX_VEL_LOSS;
        Reset();
    }

    void OnStep(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsInputTime(time) && isDone)
        {
            Eval::Advance(simManager, time, InputType::Steer, steer);
            Reset();
            Eval::Rewind(simManager);
        }
        else if (Eval::IsEvalTime(time))
        {
            const auto@ const svcCurr = simManager.SceneVehicleCar;
            const auto@ const svcPrev = Eval::MinState.SceneVehicleCar;

            const bool crashed =
                svcCurr.LastHasAnyLateralContactTime != svcPrev.LastHasAnyLateralContactTime ||
                svcCurr.CurrentLocalSpeed.Length() < (svcPrev.CurrentLocalSpeed.Length() - maxVelocityLoss);
            if (crashed)
            {
                collider = steer;
            }
            else
            {
                avoider = steer;
            }

            isDone = Math::Abs(avoider - collider) <= 1;
            if (isDone)
            {
                steer = avoider;
            }
            else
            {
                steer = (avoider + collider) >>> 1;
            }

            Eval::Rewind(simManager);
        }
        else
        {
            simManager.SetInputState(InputType::Steer, steer);
        }
    }

    void Reset()
    {
        Eval::Time::Update(seek);

        isDone = false;

        avoider = STEER::MIN * direction;
        collider = STEER::MAX * direction;
        steer = collider;
    }
}
