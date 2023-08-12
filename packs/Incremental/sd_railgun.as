// SpeedDrift Scripts

namespace SD
{
    const string NAME = "SD Railgun";
    const string DESCRIPTION = "SpeedDrift script, needs to start already drifting.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnSimulationBegin, OnSimulationStep
    );

    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("sd_" + var);
    }

    const string MODE = PrefixVar("mode");
    
    void OnRegister()
    {
        RegisterVariable(MODE, Classic::NAME);

        //ModeRegister(sdMap, Normal::mode);
        ModeRegister(sdMap, Classic::mode);
        //ModeRegister(sdMap, Wiggle::mode);

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

    void OnSimulationBegin(SimulationManager@ simManager)
    {
        sdMode.OnSimulationBegin(simManager);
    }

    void OnSimulationStep(SimulationManager@ simManager)
    {
        sdMode.OnSimulationStep(simManager);
    }

    string modeStr;
    array<string> modes;

    const Mode@ sdMode;
    dictionary sdMap;

    SimulationState@ saved;

    ms timeMin;
    ms evalTime;

    typedef float score;
    const score EVAL_SCORE_DEFAULT = -16;

    class Result
    {
        int steer;
        score result;

        Result()
        {
            result = EVAL_SCORE_DEFAULT;
        }

        Result(const int _steer, const score _result)
        {
            steer = _steer;
            result = _result;
        }
    }

    Result evalBest;
    uint evalIndex;
    array<Result> evalResults;

    int steer;
    SteeringRange steerRange;
}

namespace SD::Normal
{
    const string NAME = "Normal";
    const string DESCRIPTION = "Tries to optimize a given SD automatically.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        null, null,
        OnSimulationBegin, OnSimulationStep
    );

    const string PrefixVar(const string &in var)
    {
        return SD::PrefixVar("normal_" + var);
    }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
        Reset(simManager);
    }

    void OnSimulationStep(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (time < timeMin) return;
        else if (time == timeMin)
        {
            @saved = simManager.SaveState();
            return;
        }
        else if (time == Eval::inputTime)
        {
            steer = steerRange.Pop();
        }
        
        if (time == evalTime)
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
            simManager.RewindToState(saved);
            return;
        }

        // Check if the best value is not shared
        Result bestSoFar = evalBest;
        uint bestCounter = 0;
        for (uint i = 0; i < evalResults.Length; i++)
        {
            const Result current = evalResults[i];
            if (current.result > bestSoFar.result)
            {
                bestSoFar = current;
                bestCounter = 0;
            }
            else if (current.result == bestSoFar.result && current.steer != bestSoFar.steer)
            {
                ++bestCounter;
            }
        }
        evalResults.Resize(0);

        // Save best one and goto next, or retry on the next tick if no distinct best
        if (bestCounter == 0)
        {
            evalBest = bestSoFar;
            if (steerRange.IsDone)
            {
                Eval::Advance(simManager, Eval::inputTime, InputType::Steer, evalBest.steer);
                Reset(simManager);
                return;
            }

            steerRange.Magnify(evalBest.steer);
        }
        else
        {
            evalTime += TICK;
            steerRange.Create();
        }

        simManager.RewindToState(saved);
    }

    void Reset(SimulationManager@ simManager)
    {
        timeMin = Eval::inputTime - TICK;
        evalTime = Eval::inputTime + TWO_TICKS;

        const auto@ const car = simManager.SceneVehicleCar;
        evalBest.steer = NextTurningRate(car.InputSteer, car.TurningRate);

        const int midpoint = evalBest.steer;
        const uint deviation = 0x3000;
        const uint step = 0x1000;
        steerRange = SteeringRange(midpoint, step, deviation);
    }
}

namespace SD::Classic
{
    const string NAME = "Classic";
    const string DESCRIPTION = "The original sd_railgun normal sdmode, ported to AngelScript.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnSimulationBegin, OnSimulationStep
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

    const array<string> directions = {"Left", "Right"};
    string directionStr;
    Direction direction;
    bool isNormalDirection;

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
        direction = directions[0] == newMode ? Direction::left : Direction::right;
        directionStr = newMode;
    }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
        Reset();
    }

    void OnSimulationStep(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (time < timeMin) return;
        else if (time == timeMin)
        {
            @saved = simManager.SaveState();
            return;
        }
        else if (time == Eval::inputTime)
        {
            steer = steerRange.Pop();
        }
        
        if (time == evalTime)
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
        // Get results
        const score result = simManager.SceneVehicleCar.CurrentLocalSpeed.Length();
        if (result > evalBest.result) evalBest = Result(steer, result);

        // Rewind if not done collecting results
        if (!steerRange.IsEmpty)
        {
            simManager.RewindToState(saved);
            return;
        }

        // Goto next if end reached, or switch directions
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
                Eval::Advance(simManager, Eval::inputTime, InputType::Steer, evalBest.steer);
                Reset();
            }
        }
        else if (steerRange.step < 4)
        {
            const int midpoint = STEER::HALF * direction;
            steerRange = SteeringRange(midpoint, 1, 16);
        }
        else
        {
            steerRange.Magnify(evalBest.steer);
        }

        simManager.RewindToState(saved);
    }

    void Reset()
    {
        timeMin = Eval::inputTime - TICK;
        evalTime = Eval::inputTime + seek;

        evalBest = Result();

        const int midpoint = STEER::HALF * direction;
        steerRange = SteeringRange(midpoint, DEFAULT::STEP, DEFAULT::DEVIATION, 2);

        isNormalDirection = true;
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
        OnSimulationBegin, OnSimulationStep
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

    void OnSimulationBegin(SimulationManager@ simManager)
    {
    }

    void OnSimulationStep(SimulationManager@ simManager)
    {
    }
}
