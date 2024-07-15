// SpeedDrift Scripts

namespace SD
{
    const string NAME = "SD Railgun";
    const string DESCRIPTION = "SpeedDrift scripts.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PREFIX = ::PREFIX + "sd_";

    const string MODE = PREFIX + "mode";

    string modeStr;
    array<string> modes;

    const Mode@ sdMode;
    dictionary sdMap;

    void OnRegister()
    {
        RegisterVariable(MODE, Classic::NAME);

        ModeRegister(sdMap, Classic::mode);
        ModeRegister(sdMap, Normal::mode);
        //ModeRegister(sdMap, Wiggle::mode); // not yet implemented

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

    int steer;
    RangeIncl range;

    int bestSteer;
    double bestResult;
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

    const string PREFIX = SD::PREFIX + "classic_";

    const string SEEK      = PREFIX + "seek";
    const string DIRECTION = PREFIX + "direction";

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
        RegisterVariable(SEEK, 120);
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

    const int LAST_OFFSET = 8;

    int step;
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
            steer = range.Iter();
        }
        
        if (Eval::IsEvalTime(time))
        {
            OnEval(simManager);
            Eval::Rewind(simManager);
        }
        else
        {
            simManager.SetInputState(InputType::Steer, steer);
        }
    }

    void OnEval(SimulationManager@ simManager)
    {
        const double result = simManager.Dyna.RefStateCurrent.LinearSpeed.Length();
        if (result > bestResult)
        {
            bestSteer = steer;
            bestResult = result;
        }

        if (!range.Done) return; // not done with range
        
        if (step <= 1) // done with iteration
        {
            const bool switchDirection = isNormalDirection && bestSteer * direction < 0;
            if (switchDirection)
            {
                isNormalDirection = false;

                const int midpoint = -STEER::HALF * direction;
                step = 0x4000;
                SetRangeAroundMidpoint(midpoint);
            }
            else
            {
                Eval::Advance(simManager, bestSteer);
                Reset();
            }
        }
        else if (DecreaseStep() <= 1) // last step before we are done
        {
            const int midpoint = bestSteer;
            range = RangeIncl(midpoint - LAST_OFFSET, midpoint + LAST_OFFSET, 1);
        }
        else // not done with iteration, keep 'magnifying'
        {
            DecreaseStep();
            SetRangeAroundMidpoint(bestSteer);
        }
    }

    void Reset()
    {
        Eval::Time::OffsetEval(seek);
        bestResult = -1;

        const int midpoint = STEER::HALF * direction;
        step = 0x4000;
        SetRangeAroundMidpoint(midpoint);
        isNormalDirection = true;
    }

    void SetRangeAroundMidpoint(const int midpoint)
    {
        const int offset = step * 3 / 2;
        range = RangeIncl(midpoint - offset, midpoint + offset, step);
    }

    int DecreaseStep()
    {
        return step >>= 2;
    }
}

namespace SD::Normal
{
    const string NAME = "Normal";
    const string DESCRIPTION = "Tries to optimize a given SD automatically.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PREFIX = SD::PREFIX + "normal_";

    const string SEEK = PREFIX + "seek";

    ms seek;

    void OnRegister()
    {
        RegisterVariable(SEEK, 120);
        seek = ms(GetVariableDouble(SEEK));
    }

    void OnSettings()
    {
        seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
    }

    const OnSim@ onStep;
    int step; // not confusing whatsoever

    void OnBegin(SimulationManager@ simManager)
    {
        Reset();
    }

    void OnStep(SimulationManager@ simManager)
    {
        onStep(simManager);
    }

    void OnStepPre(SimulationManager@ simManager)
    {
        const float prevTurningRate = Eval::MinState.SceneVehicleCar.TurningRate;
        const float turningRate = simManager.SceneVehicleCar.TurningRate;
        bestSteer = RoundAway(turningRate * STEER::FULL, turningRate - prevTurningRate);

        step = 0x4000;
        SetRangeAroundMidpoint(bestSteer);

        @onStep = OnStepMain;
        onStep(simManager);
    }

    void OnStepMain(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsInputTime(time))
        {
            steer = range.Iter();
        }
        
        if (Eval::IsEvalTime(time))
        {
            OnEval(simManager);
            Eval::Rewind(simManager);
        }
        else
        {
            simManager.SetInputState(InputType::Steer, steer);
        }
    }

    void OnEval(SimulationManager@ simManager)
    {
        const double result = simManager.Dyna.RefStateCurrent.LinearSpeed.Length();
        if (result > bestResult)
        {
            bestSteer = steer;
            bestResult = result;
        }

        if (!range.Done) return;

        if (step == 0)
        {
            Eval::Advance(simManager, bestSteer);
            Reset();
        }
        else
        {
            step >>= 2;
            SetRangeAroundMidpoint(bestSteer);
        }
    }

    void Reset()
    {
        Eval::Time::OffsetEval(seek);
        bestResult = -1;

        @onStep = OnStepPre;
    }

    void SetRangeAroundMidpoint(const int midpoint)
    {
        const int offset = step * 3 / 2;
        range = RangeIncl(midpoint - offset, midpoint + offset, step);
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

    const string PREFIX = SD::PREFIX + "wiggle_";
    
    const string ANGLE    = PREFIX + "angle";
    const string POSITION = PREFIX + "position";

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
