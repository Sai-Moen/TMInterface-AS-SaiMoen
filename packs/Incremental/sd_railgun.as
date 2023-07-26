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

    IMode@ sdMode;
    dictionary sdMap;

    void ModeDispatch(const string key = mode)
    {
        @sdMode = cast<IMode>(sdMap[key]);
    }

    void ModeRegister(IMode@ const sdMode)
    {
        @sdMap[sdMode.GetName()] = sdMode;
        sdMode.OnRegister();
    }
    
    // SimpleStep
    funcdef void SimpleStep(SimulationManager@ simManager);
    const SimpleStep@ step;

    // Seek
    const string AUTO_SEEK = PrefixVar("auto_seek");
    const string SEEK      = PrefixVar("seek");

    const ms SEEK_MAX = 240;

    funcdef bool OnSeek();
        
    bool autoSeek;
    ms seek;

    // Normal
    const string DIRECTION = PrefixVar("direction");

    // Wiggle
    const string WIGGLE_A = PrefixVar("wiggle_a");
    const string WIGGLE_X = PrefixVar("wiggle_x");
    const string WIGGLE_Y = PrefixVar("wiggle_y");
    const string WIGGLE_Z = PrefixVar("wiggle_z");

    // Main classes

    class SDRailgun : Script
    {
        const string GetName() const
        {
            return "SD Railgun";
        }

        const string GetDescription() const
        {
            return "SpeedDrift script, needs to start already drifting.";
        }

        void OnRegister() const
        {
            // Register
            RegisterVariable(MODE, MODE_DEFAULT);

            RegisterVariable(AUTO_SEEK, true);
            RegisterVariable(SEEK, 120);

            // Register sub-modes
            ModeRegister(ModeNormal());
            ModeRegister(ModeWiggle());

            // Init
            mode = GetVariableString(MODE);
            ModeDispatch();

            modes = sdMap.GetKeys();
            modes.SortAsc();

            autoSeek = GetVariableBool(AUTO_SEEK);
            seek = ms(GetVariableDouble(SEEK));
        }

        void OnSettings() const
        {
            autoSeek = UI::CheckboxVar("Use automatic seek?", AUTO_SEEK);
            UI::BeginDisabled(autoSeek);
            seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
            UI::EndDisabled();

            UI::Separator();

            if (ComboHelper("SD Mode", mode, modes, @OnNewMode(ChangeMode)))
            {
                DescribeModes("SD Modes:", modes, sdMap);
            }

            sdMode.OnSettings();
        }

        void ChangeMode(const string &in newMode) const
        {
            SetVariable(MODE, newMode);
            mode = newMode;
            ModeDispatch();
        }

        void OnSimulationBegin(SimulationManager@ simManager) const
        {
            ModeDispatch();
            @step = @SimpleStep(sdMode.OnSimulationStep);
            sdMode.ChooseSeek(autoSeek);
        }

        void OnSimulationStep(SimulationManager@ simManager) const
        {
            step(simManager);
        }
    }

    interface IMode : Describable
    {
        void OnRegister();
        void OnSettings();

        void ChooseSeek(const bool autoSeek);
        void OnSimulationStep(SimulationManager@ simManager);
    }

    mixin class MMode : IMode
    {
        const SimulationState@ saved;
        const SimulationState@ current;

        ms time;
        int steer;

        // Determine if looked ahead far enough
        const OnSeek@ onSeek;

        void ChooseSeek(const bool autoSeek)
        {
            @onSeek = autoSeek ? @OnSeek(OnAutoSeek) : @OnSeek(OnManualSeek);
        }

        bool OnAutoSeek() const
        {
            return true;
        }

        bool OnManualSeek() const
        {
            return time == inputTime + seek;
        }
    }

    class ModeNormal : MMode
    {
        const string GetName() const
        {
            return MODE_DEFAULT;
        }

        const string GetDescription() const
        {
            return "Goes in the given direction.";
        }

        int direction;

        void OnRegister()
        {
            RegisterVariable(DIRECTION, 0);

            direction = int(GetVariableDouble(DIRECTION));
        }

        void OnSettings()
        {
            direction = UI::SliderIntVar("Direction", DIRECTION, Direction::left, Direction::right, "");
            direction = direction == Direction::left ? -1 : 1;
            UI::SameLine();
            UI::TextWrapped("= " + direction);
        }

        void OnSimulationStep(SimulationManager@ simManager)
        {
            const ms timeMin = inputTime - TICK;

            time = simManager.get_TickTime();
            if (time < timeMin) return;
            else if (time == timeMin)
            {
                @saved = simManager.SaveState();
            }
            else if (time == inputTime)
            {
                steer = GetSteer();
            }
            else if (time == inputTime + TWO_TICKS)
            {
                @current = simManager.SaveState();
            }
        }

        int GetSteer()
        {
            return 0;
        }
    }

    class ModeWiggle : MMode
    {
        const string GetName() const
        {
            return "Wiggle";
        }

        const string GetDescription() const
        {
            return "Goes in the direction of the point,"
                + " switching directions when facing too far away.";
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
