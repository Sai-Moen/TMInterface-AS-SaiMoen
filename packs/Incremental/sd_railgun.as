// SpeedDrift Script

namespace SD
{
    // SD sub-modes
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

    const string DEFAULT_MODE = modes[Mode::normal];

    // SD Wiggle point vars
    const string WIGGLE_A = VAR_PREFIX + "wiggle_a";
    const string WIGGLE_X = VAR_PREFIX + "wiggle_x";
    const string WIGGLE_Y = VAR_PREFIX + "wiggle_y";
    const string WIGGLE_Z = VAR_PREFIX + "wiggle_z";
}

class SDRailgun : MScript
{
    string name { get const { return "SD Railgun"; } }

    SD::Mode mode;

    void RegisterVars()
    {
        RegisterVariable(SD::MODE, SD::DEFAULT_MODE);

        RegisterVariable(SD::WIGGLE_A, 15);
        RegisterVariable(SD::WIGGLE_X, 0);
        RegisterVariable(SD::WIGGLE_Y, 0);
        RegisterVariable(SD::WIGGLE_Z, 0);

        string currentMode = GetVariableString(SD::MODE);
        mode = SD::Mode(SD::modes.Find(currentMode));
    }

    void OnSettings()
    {
        string currentMode = GetVariableString(SD::MODE);
        if (UI::BeginCombo("SD Mode", currentMode))
        {
            for (uint i = 0; i < SD::modes.Length; i++)
            {
                string newMode = SD::modes[i];
                if (UI::Selectable(newMode, currentMode == newMode))
                {
                    SetVariable(SD::MODE, newMode);
                    mode = SD::Mode(i);
                }
            }

            UI::EndCombo();
        }

        switch (mode)
        {
        case SD::Mode::normal:
            break;
        case SD::Mode::wiggle:
            UI::TextWrapped("Maximum angle away from point");
            UI::SliderFloatVar("", SD::WIGGLE_A, 0, 90);
            UI::InputFloatVar("Point x-position", SD::WIGGLE_X);
            UI::InputFloatVar("Point y-position", SD::WIGGLE_Y);
            UI::InputFloatVar("Point z-position", SD::WIGGLE_Z);
            break;
        }
    }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
    }

    void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
    {
    }
}

SDRailgun sd;
