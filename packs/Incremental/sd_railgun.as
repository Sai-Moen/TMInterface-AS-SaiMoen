// SpeedDrift Script

namespace SD
{
    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("sd_" + var);
    }

    // Modes
    const string MODE = PrefixVar("mode");
    const string MODE_DEFAULT = "Normal";

    string mode;
    array<string> modes;

    ScriptClass@ sdMode;
    dictionary sdMap;

    // SimpleStep
    funcdef void SimpleStep(SimulationManager@ simManager);
    const SimpleStep@ step;

    SimulationState@ saved;

    ms time;
    int steer;
    
    // Main classes

    class SDRailgun : Script
    {
        const string name
        {
            get const { return "SD Railgun"; }
        }

        const string description
        {
            get const { return "SpeedDrift script, needs to start already drifting."; }
        }

        void OnRegister() const
        {
            // Register
            RegisterVariable(MODE, MODE_DEFAULT);

            // Register sub-modes
            ScriptClassRegister(sdMap, ModeNormal());
            ScriptClassRegister(sdMap, ModeWiggle());

            // Init
            mode = GetVariableString(MODE);
            ScriptClassDispatch(mode, sdMap, sdMode);

            modes = sdMap.GetKeys();
            modes.SortAsc();
        }

        void OnSettings() const
        {
            if (ComboHelper("SD Mode", mode, modes, @OnNewMode(ChangeMode)))
            {
                DescribeModes("SD Modes:", modes, sdMap);
            }

            sdMode.OnSettings();
        }

        void ChangeMode(const string &in newMode) const
        {
            ScriptClassDispatch(newMode, sdMap, sdMode);
            SetVariable(MODE, newMode);
            mode = newMode;
        }

        void OnSimulationBegin(SimulationManager@ simManager) const
        {
        }

        void OnSimulationStep(SimulationManager@ simManager) const
        {
            sdMode.OnSimulationStep(simManager);
        }
    }

    // Normal
    const string DIRECTION = PrefixVar("direction");

    class ModeNormal : ScriptClass
    {
        const string name
        {
            get const { return MODE_DEFAULT; }
        }

        const string description
        {
            get const { return "Goes in the given direction."; }
        }

        void OnRegister()
        {
            RegisterVariable(DIRECTION, 0);

            direction = int(GetVariableDouble(DIRECTION));
        }

        void OnSettings()
        {
            direction = UI::SliderIntVar("Direction", DIRECTION, Direction::left, Direction::right, "");

            UI::SameLine();
            UI::TextWrapped("= " + direction);
        }

        int _direction;
        int direction
        {
            get { return _direction; }
            set { _direction = value == Direction::left ? -1 : 1; }
        }

        int testTime;
        array<int> steerRange;

        void OnSimulationBegin(SimulationManager@ simManager)
        {
            Reset();
        }

        void OnSimulationStep(SimulationManager@ simManager)
        {
            const ms timeMin = inputTime - TICK;

            time = simManager.TickTime;
            if (time < timeMin) return;
            else if (time == timeMin)
            {
                @saved = simManager.SaveState();
                return;
            }
            
            if (time >= inputTime)
            {
                simManager.SetInputState(InputType::Steer, steer);
            }
            
            if (time == testTime)
            {
                // Eval
                simManager.RewindToState(saved);
            }
        }

        void Reset()
        {
            testTime = inputTime + TWO_TICKS;
            steerRange = {};
        }
    }

    // Wiggle
    const string WIGGLE_A = PrefixVar("wiggle_a");
    const string WIGGLE_X = PrefixVar("wiggle_x");
    const string WIGGLE_Y = PrefixVar("wiggle_y");
    const string WIGGLE_Z = PrefixVar("wiggle_z");

    class ModeWiggle : ScriptClass
    {
        const string name
        {
            get const { return "Wiggle"; }
        }

        const string description
        {
            get const
            {
                return "Goes in the direction of the point,"
                    + " switching directions when facing too far away.";
            }
        }

        Wiggle wiggle;

        void OnRegister()
        {
            RegisterVariable(WIGGLE_A, 15);
            RegisterVariable(WIGGLE_X, 0);
            RegisterVariable(WIGGLE_Y, 0);
            RegisterVariable(WIGGLE_Z, 0);

            wiggle.angle = GetVariableDouble(WIGGLE_A);
            wiggle.x     = GetVariableDouble(WIGGLE_X);
            wiggle.y     = GetVariableDouble(WIGGLE_Y);
            wiggle.z     = GetVariableDouble(WIGGLE_Z);
        }

        void OnSettings()
        {
            UI::TextWrapped("Maximum angle away from point");
            wiggle.angle = UI::SliderFloatVar("", WIGGLE_A, 0, 45);
            wiggle.x = UI::InputFloatVar("Point x-position", WIGGLE_X);
            wiggle.y = UI::InputFloatVar("Point y-position", WIGGLE_Y);
            wiggle.z = UI::InputFloatVar("Point z-position", WIGGLE_Z);
        }

        void OnSimulationBegin(SimulationManager@ simManager)
        {
        }

        void OnSimulationStep(SimulationManager@ simManager)
        {
        }
    }

    class Wiggle
    {
        double angle;
        double x;
        double y;
        double z;
    }
}
