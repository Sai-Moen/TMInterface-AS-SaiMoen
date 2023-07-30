// SpeedDrift Script

namespace SD
{
    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("sd_" + var);
    }

    // Modes
    const string MODE = PrefixVar("mode");
    
    const string NAME = "SD Railgun";
    const string DESCRIPTION = "SpeedDrift script, needs to start already drifting.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnSimulationBegin, OnSimulationStep
    );

    void OnRegister()
    {
        // Register
        RegisterVariable(MODE, Normal::NAME);

        // Register sub-modes
        ModeRegister(sdMap, Normal::mode);
        ModeRegister(sdMap, Classic::mode);
        ModeRegister(sdMap, Wiggle::mode);

        // Init
        modeStr = GetVariableString(MODE);
        ModeDispatch(modeStr, sdMap, sdMode);

        modes = sdMap.GetKeys();
        modes.SortAsc();
    }

    void OnSettings()
    {
        if (ComboHelper("SD Mode", modeStr, modes, @OnNewMode(ChangeMode)))
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

    // Eval
    const score EVAL_SCORE_DEFAULT = -16;

    SimulationState@ saved;
    int steer;
    
    ms timeMin;

    ms evalTime;
    Result evalBest;
    array<Result> evalResults;

    int step;
    array<int> steerRange;

    typedef float score;
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

    // Normal
    namespace Normal
    {
        const string NAME = "Normal";
        const string DESCRIPTION = "Tries to optimize a given SD automatically.";
        const Mode@ const mode = Mode(
            NAME, DESCRIPTION,
            OnRegister, OnSettings,
            OnSimulationBegin, OnSimulationStep
        );

        funcdef int GetSteer(SimulationManager@ simManager);
        GetSteer@ getSteer;

        void OnRegister()
        {
        }

        void OnSettings()
        {
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
            else if (time == inputTime)
            {
                steer = getSteer(simManager);
            }
            
            if (time == evalTime)
            {
                OnEval(simManager);
            }
            else // Expect: (time >= inputTime && time < evalTime)
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
            if (steerRange.Length > 0)
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
                    bestCounter = 1;
                }
                else if (current.result == bestSoFar.result && current.steer != bestSoFar.steer)
                {
                    ++bestCounter;
                }
            }
            evalResults.Resize(0);

            // Save best one and goto next, or retry on the next tick if no distinct best
            if (bestCounter == 1)
            {
                evalBest = bestSoFar;
                Magnify(simManager.InputEvents);
            }
            else
            {
                Retry();
            }

            simManager.RewindToState(saved);
        }

        void Reset()
        {
            @getSteer = @GetSteer(GetSteerPre);

            timeMin = inputTime - TICK;

            evalTime = inputTime + TWO_TICKS;

            // TODO: setup steering range and matching results
        }

        int GetSteerPre(SimulationManager@ simManager)
        {
            const TM::SceneVehicleCar@ const car = simManager.SceneVehicleCar;
            evalBest.steer = int(FULLSTEER * NextTurningRate(car.InputSteer, car.TurningRate));

            @getSteer = @GetSteer(GetSteerMain);
            return getSteer(simManager);
        }

        int GetSteerMain(SimulationManager@ simManager)
        {
            int steer = ClampSteer(evalBest.steer + steerRange[0]);
            steerRange.RemoveAt(0);
            return steer;
        }

        void Magnify(TM::InputEventBuffer@ const buffer)
        {
            if (step == 1)
            {
                buffer.Add(inputTime, InputType::Steer, evalBest.steer);
                inputTime += TICK;
                Reset();
                return;
            }

            step >>= 1;
            MakeRange();
        }

        void Retry()
        {
            evalTime += TICK;
            MakeRange();
        }
    }

    // Classic
    const string SEEK = PrefixVar("seek");
    const string DIRECTION = PrefixVar("direction");

    namespace Classic
    {
        const string NAME = "Classic";
        const string DESCRIPTION = "The original sd_railgun normal sdmode, ported to AngelScript.";
        const Mode@ const mode = Mode(
            NAME, DESCRIPTION,
            OnRegister, OnSettings,
            OnSimulationBegin, OnSimulationStep
        );

        const ms SEEK_DEFAULT = 120;
        ms seek;

        enum DirectionIndex
        {
            left, right,
        }

        enum Direction
        {
            left = -1,
            right = 1,
        }

        const array<string> directions = {"Left", "Right"};
        string directionStr;
        Direction direction;
        
        void OnRegister()
        {
            RegisterVariable(SEEK, SEEK_DEFAULT);
            RegisterVariable(DIRECTION, directions[DirectionIndex::left]);

            seek = ms(GetVariableDouble(SEEK));
            directionStr = GetVariableString(DIRECTION);
        }

        void OnSettings()
        {
            seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);

            ComboHelper("Direction", directionStr, directions, @OnNewMode(ChangeMode));
        }

        void ChangeMode(const string &in newMode)
        {
            direction = directions[DirectionIndex::left] == newMode ?
                Direction::left : Direction::right;
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
            else if (time == inputTime)
            {
                steer = GetSteer();
            }
            
            if (time == evalTime)
            {
                OnEval(simManager);
            }
            else // Expect: (time >= inputTime && time < evalTime)
            {
                simManager.SetInputState(InputType::Steer, steer);
            }
        }

        void OnEval(SimulationManager@ simManager)
        {
            // Get results
            const score result = simManager.SceneVehicleCar.CurrentLocalSpeed.Length();
            evalResults.Add(Result(steer, result));

            // Rewind if not done collecting results
            if (steerRange.Length > 0)
            {
                simManager.RewindToState(saved);
                return;
            }

            // Set best result
            for (uint i = 0; i < evalResults.Length; i++)
            {
                const Result current = evalResults[i];
                if (current.result > evalBest.result)
                {
                    evalBest = current;
                }
            }

            // Goto next if end reached
            if (step == 1)
            {
                simManager.InputEvents.Add(inputTime, InputType::Steer, evalBest.steer);
                inputTime += TICK;
                Reset();
                simManager.RewindToState(saved);
                return;
            }

            step >>= 1;
            MakeRange();

            simManager.RewindToState(saved);
        }

        int GetSteer()
        {
            int steer = ClampSteer(evalBest.steer + steerRange[0]);
            steerRange.RemoveAt(0);
            return steer;
        }

        void Reset()
        {
            timeMin = inputTime - TICK;

            evalTime = inputTime + seek;
            
            // TODO: setup steering range and matching results
        }
    }

    // Wiggle
    const string WIGGLE_ANGLE    = PrefixVar("wiggle_angle");
    const string WIGGLE_POSITION = PrefixVar("wiggle_position");

    namespace Wiggle
    {
        const string NAME = "Wiggle";
        const string DESCRIPTION = "Goes in the direction of the point,"
            + " switching directions when facing too far away.";
        const Mode@ const mode = Mode(
            NAME, DESCRIPTION,
            OnRegister, OnSettings,
            OnSimulationBegin, OnSimulationStep
        );
        
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
            RegisterVariable(WIGGLE_ANGLE, 15);
            RegisterVariable(WIGGLE_POSITION, ".0,.0,.0");

            wiggle.angle = GetVariableDouble(WIGGLE_ANGLE);
            vec3 v = Text::ParseVec3(GetVariableString(WIGGLE_POSITION));
            wiggle.x = v.x;
            wiggle.y = v.y;
            wiggle.z = v.z;
        }

        void OnSettings()
        {
            wiggle.angle = UI::SliderFloatVar("Maximum angle away from point", WIGGLE_ANGLE, 0, 45);
            UI::DragFloat3Var("Point position", WIGGLE_POSITION);
            vec3 v = Text::ParseVec3(GetVariableString(WIGGLE_POSITION));
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
}
