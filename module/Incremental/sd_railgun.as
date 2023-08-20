// SpeedDrift Scripts

namespace SD
{
    const string NAME = "SD Railgun";
    const string DESCRIPTION = "SpeedDrift script, needs to start already drifting.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("sd_" + var);
    }

    const string MODE = PrefixVar("mode");

    string modeStr;
    array<string> modes;

    const Mode@ sdMode;
    dictionary sdMap;

    void OnRegister()
    {
        RegisterVariable(MODE, Classic::NAME);

        //ModeRegister(sdMap, Normal::mode); thinking about it
        ModeRegister(sdMap, Classic::mode);
        //ModeRegister(sdMap, Wiggle::mode); not yet implemented

        modeStr = GetVariableString(MODE);
        ModeDispatch(modeStr, sdMap, sdMode);

        modes = sdMap.GetKeys();
        modes.SortAsc();
    }

    void OnSettings()
    {
        if (ComboHelper("SD Mode", modeStr, modes, ChangeMode))
        {
            DescribeModes("SD Modes:", modes, sdMap);
        }

        sdMode.OnSettings();
    }

    void ChangeMode(const string &in newMode)
    {
        ModeDispatch(newMode, sdMap, sdMode);
        SetVariable(MODE, newMode);
        modeStr = newMode;
    }

    void OnBegin(SimulationManager@ simManager)
    {
        sdMode.OnBegin(simManager);
    }

    void OnStep(SimulationManager@ simManager)
    {
        sdMode.OnStep(simManager);
    }

    Result evalBest;
    array<Result> evalResults;

    int steer;
    SteeringRange steerRange;

    typedef float score;
    class Result
    {
        int steer;
        score result;

        Result()
        {
            result = -16;
        }

        Result(const int _steer, const score _result)
        {
            steer = _steer;
            result = _result;
        }
    }
}

namespace SD::Classic
{
    const string NAME = "Classic";
    const string DESCRIPTION = "The original sd_railgun normal sdmode, ported to AngelScript.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PrefixVar(const string &in var)
    {
        return SD::PrefixVar("classic_" + var);
    }

    const string SEEK = PrefixVar("seek");
    const string DIRECTION = PrefixVar("direction");

    namespace DEFAULT
    {
        const ms SEEK = 120;
            
        const uint STEP = 0x4000;
        const uint DEVIATION = 0x6000;
    }

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
        RegisterVariable(SEEK, DEFAULT::SEEK);
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
        SetVariable(DIRECTION, newMode);
        direction = directions[0] == newMode ? Direction::left : Direction::right;
        directionStr = newMode;
    }

    bool isNormalDirection;

    void OnBegin(SimulationManager@ simManager)
    {
        Reset();
    }

    void OnStep(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsInputTime(time))
        {
            steer = steerRange.Pop();
        }
        
        if (Eval::IsEvalTime(time))
        {
            OnEval(simManager);
        }
        else
        {
            simManager.SetInputState(InputType::Steer, steer);
        }
    }

    void OnEval(SimulationManager@ simManager)
    {
        const score result = simManager.SceneVehicleCar.CurrentLocalSpeed.Length();
        if (result > evalBest.result) evalBest = Result(steer, result);

        if (!steerRange.IsEmpty)
        {
            Eval::Rewind(simManager);
            return;
        }

        if (steerRange.IsDone)
        {
            const bool switchDirection = isNormalDirection && evalBest.steer * direction < 0;
            if (switchDirection)
            {
                isNormalDirection = false;

                const int midpoint = -STEER::HALF * direction;
                steerRange = SteeringRange(midpoint, DEFAULT::STEP, DEFAULT::DEVIATION, 2);
            }
            else
            {
                Eval::Advance(simManager, evalBest.steer);
                Reset();
            }
        }
        else if (steerRange.IsLast)
        {
            const int midpoint = STEER::HALF * direction;
            steerRange = SteeringRange(midpoint, 1, 16);
        }
        else
        {
            steerRange.Magnify(evalBest.steer);
        }

        Eval::Rewind(simManager);
    }

    void Reset()
    {
        Eval::Time::Update(seek);

        evalBest = Result();

        const int midpoint = STEER::HALF * direction;
        steerRange = SteeringRange(midpoint, DEFAULT::STEP, DEFAULT::DEVIATION, 2);

        isNormalDirection = true;
    }
}

namespace SD::Normal
{
    const string NAME = "Normal";
    const string DESCRIPTION = "Tries to optimize a given SD automatically.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        null, null,
        OnBegin, OnStep
    );

    const string PrefixVar(const string &in var)
    {
        return SD::PrefixVar("normal_" + var);
    }

    const OnSim@ step;

    void OnBegin(SimulationManager@ simManager)
    {
        Reset();
    }

    void OnStepPre(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsInputTime(time))
        {
            const auto@ const svc = simManager.SceneVehicleCar;
            evalBest.steer = NextTurningRate(svc.InputSteer, svc.TurningRate);
            steerRange.Midpoint = evalBest.steer;
            steer = steerRange.Pop();
            @step = OnStepMain;
        }
    }

    void OnStepMain(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsInputTime(time))
        {
            steer = steerRange.Pop();
        }
        
        if (Eval::IsEvalTime(time))
        {
            OnEval(simManager);
        }
        else
        {
            simManager.SetInputState(InputType::Steer, steer);
        }
    }

    void OnEval(SimulationManager@ simManager)
    {
        // Gather results
        const score result = simManager.SceneVehicleCar.TotalCentralForceAdded.z;
        evalResults.Add(Result(steer, result));

        // Continue until empty range
        if (!steerRange.IsEmpty)
        {
            Eval::Rewind(simManager);
            return;
        }

        // ??

        // Profit
    }

    void Reset()
    {
        Eval::Time::Update(TWO_TICKS);

        @step = OnStepPre;

        const int midpoint = 0;
        const uint deviation = 0x3000;
        const uint step = 0x1000;
        steerRange = SteeringRange(midpoint, step, deviation);
    }
}

namespace SD::Wiggle
{
    const string NAME = "Wiggle";
    const string DESCRIPTION = "Goes in the direction of the point,"
        + " switching directions when facing too far away.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PrefixVar(const string &in var)
    {
        return SD::PrefixVar("wiggle_" + var);
    }
    
    const string ANGLE    = PrefixVar("angle");
    const string POSITION = PrefixVar("position");

    const double ANGLE_MIN = 0;
    const double ANGLE_MAX = 45;

    class WiggleContext
    {
        double angle;
        double x;
        double y;
        double z;
    }

    WiggleContext wiggle;

    void OnRegister()
    {
        RegisterVariable(ANGLE, 15);
        RegisterVariable(POSITION, vec3().ToString());

        wiggle.angle = GetVariableDouble(ANGLE);
        const string position = GetVariableString(POSITION);
        vec3 v = Text::ParseVec3(position);
        wiggle.x = v.x;
        wiggle.y = v.y;
        wiggle.z = v.z;
    }

    void OnSettings()
    {
        wiggle.angle = UI::SliderFloatVar("Maximum angle away from point", ANGLE, ANGLE_MIN, ANGLE_MAX);
        wiggle.angle = Math::Clamp(wiggle.angle, ANGLE_MIN, ANGLE_MAX);
        SetVariable(ANGLE, wiggle.angle);

        UI::DragFloat3Var("Point position", POSITION);
        vec3 v = Text::ParseVec3(GetVariableString(POSITION));
        wiggle.x = v.x;
        wiggle.y = v.y;
        wiggle.z = v.z;
    }

    void OnBegin(SimulationManager@ simManager)
    {
    }

    void OnStep(SimulationManager@ simManager)
    {
    }
}
