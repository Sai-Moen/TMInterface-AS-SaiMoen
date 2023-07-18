// SpeedDrift Script

namespace SD
{
    // SD seek vars
    const string AUTO_SEEK = VAR_PREFIX + "sd_auto_seek";
    const string SEEK      = VAR_PREFIX + "sd_seek";

    // SD sub-mode vars
    const string MODE = VAR_PREFIX + "sd_mode";

    const array<string> modes =
    {
        "Normal",
        "Wiggle"
    };

    enum Mode
    {
        normal,
        wiggle,
    }

    const string MODE_DEFAULT = modes[Mode::normal];

    // SD Wiggle point vars
    const string WIGGLE_A = VAR_PREFIX + "wiggle_a";
    const string WIGGLE_X = VAR_PREFIX + "wiggle_x";
    const string WIGGLE_Y = VAR_PREFIX + "wiggle_y";
    const string WIGGLE_Z = VAR_PREFIX + "wiggle_z";

    const double ANGLE_DEFAULT = 15;
    const double POS_DEFAULT = 0;

    class Wiggle
    {
        Wiggle()
        {
            angle = ANGLE_DEFAULT;
            x = POS_DEFAULT;
            y = POS_DEFAULT;
            z = POS_DEFAULT;
        }

        Wiggle(double a, double _x, double _y, double _z)
        {
            angle = a;
            x = _x;
            y = _y;
            z = _z;
        }

        double angle;
        double x;
        double y;
        double z;
    }

    // Script settings
    bool autoSeek;
    int seek;

    string mode;
    Mode modeState;

    Wiggle wiggle;

    void RegisterVars()
    {
        RegisterVariable(AUTO_SEEK, true);
        RegisterVariable(SEEK, 120);

        RegisterVariable(MODE, MODE_DEFAULT);

        RegisterVariable(WIGGLE_A, ANGLE_DEFAULT);
        RegisterVariable(WIGGLE_X, POS_DEFAULT);
        RegisterVariable(WIGGLE_Y, POS_DEFAULT);
        RegisterVariable(WIGGLE_Z, POS_DEFAULT);

        string currentMode = GetVariableString(MODE);
        mode = Mode(modes.Find(currentMode));
    }

    void OnSettings()
    {
        autoSeek = UI::CheckboxVar("Use automatic seek?", AUTO_SEEK);
        UI::BeginDisabled(autoSeek);
        seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK_MS);
        UI::EndDisabled();

        if (UI::BeginCombo("SD Mode", mode))
        {
            for (uint i = 0; i < modes.Length; i++)
            {
                string newMode = modes[i];
                if (UI::Selectable(newMode, mode == newMode))
                {
                    SetVariable(MODE, newMode);
                    mode = newMode;
                    modeState = Mode(i);
                }
            }

            UI::EndCombo();
        }

        switch (modeState)
        {
        case Mode::normal:
            break;
        case Mode::wiggle:
            UI::TextWrapped("Maximum angle away from point");
            wiggle.angle = UI::SliderFloatVar("", WIGGLE_A, 0, 45);
            wiggle.x = UI::InputFloatVar("Point x-position", WIGGLE_X);
            wiggle.y = UI::InputFloatVar("Point y-position", WIGGLE_Y);
            wiggle.z = UI::InputFloatVar("Point z-position", WIGGLE_Z);
            break;
        }
    }

    // Simulation
    SimpleStep@ step;
    OnSeek@ onSeek;

    void OnSimulationBegin()
    {
        switch(modeState)
        {
        case Mode::normal:
            @step = OnSimulationStepNormal;
            break;
        case Mode::wiggle:
            @step = OnSimulationStepWiggle;
            break;
        }

        @onSeek = autoSeek ? OnAutoSeek : OnManualSeek;
    }

    funcdef void SimpleStep(SimulationManager@ simManager);

    void OnSimulationStepNormal(SimulationManager@ simManager)
    {
    }

    void OnSimulationStepWiggle(SimulationManager@ simManager)
    {
    }

    funcdef bool OnSeek();

    bool OnAutoSeek()
    {
        return true;
    }

    bool OnManualSeek()
    {
        return true;
    }
}

class SDRailgun : MScript
{
    const string GetName()
    {
        return "SD Railgun";
    }

    void RegisterVars()
    {
        SD::RegisterVars();
    }

    void OnSettings()
    {
        SD::OnSettings();
    }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
        simManager.RemoveStateValidation();

        SD::OnSimulationBegin();
    }

    void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
    {
        if (userCancelled) return;

        SD::step(simManager);
    }
}

SDRailgun sd;
