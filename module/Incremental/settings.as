// Settings/vars/ui Script, extension of common

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string MODE       = PrefixVar("mode");

const string EVAL_RANGE = PrefixVar("eval_range");
const string EVAL_TO    = PrefixVar("eval_to");
const string TIME_FROM  = PrefixVar("time_from");
const string TIME_TO    = PrefixVar("time_to");

const string RANGE_MODE = PrefixVar("range_mode");

const string SHOW_INFO = PrefixVar("show_info");

string modeStr;
array<string> modes;

namespace Settings
{
    bool evalRange;
    ms evalTo;
    ms timeFrom;
    ms timeTo;

    bool showInfo;
    void PrintInfo(SimulationManager@ simManager, const string &in script)
    {
        string printable = script;
        if (showInfo)
        {
            printable += " -> " + simManager.SceneVehicleCar.CurrentLocalSpeed.Length() + " m/s";
        }
        print(printable);
    }
}

void OnRegister()
{
    // Register
    RegisterVariable(MODE, NONE::NAME);

    RegisterVariable(EVAL_RANGE, false);
    RegisterVariable(EVAL_TO, 0);
    RegisterVariable(TIME_FROM, 0);
    RegisterVariable(TIME_TO, 10000);

    RegisterVariable(RANGE_MODE, Range::modes[0]);

    RegisterVariable(SHOW_INFO, true);

    // Register sub-modes
    ModeRegister(modeMap, NONE::mode);

    ModeRegister(modeMap, SD::mode);
    ModeRegister(modeMap, WH::mode);

    Entry::OnRegister();

    // Init
    modeStr = GetVariableString(MODE);
    ModeDispatch(modeStr, modeMap, mode);

    modes = modeMap.GetKeys();
    modes.SortAsc();

    Settings::evalRange = GetVariableBool(EVAL_RANGE);
    Settings::evalTo    = ms(GetVariableDouble(EVAL_TO));
    Settings::timeFrom  = ms(GetVariableDouble(TIME_FROM));
    Settings::timeTo    = ms(GetVariableDouble(TIME_TO));

    Range::mode = GetVariableString(RANGE_MODE);
    Range::ChangeMode(Range::mode);

    Settings::showInfo = GetVariableBool(SHOW_INFO);
}

void OnSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        Settings::evalRange = UI::CheckboxVar("Evaluate timerange?", EVAL_RANGE);
        if (Settings::evalRange)
        {
            Settings::timeFrom = UI::InputTimeVar("Minimum starting time", TIME_FROM);
            CapMax(EVAL_TO, Settings::timeFrom, Settings::evalTo);

            Settings::evalTo = UI::InputTimeVar("Maximum starting time", EVAL_TO);
            CapMax(TIME_TO, Settings::evalTo, Settings::timeTo);

            ComboHelper(
                "Prioritize ... on final tick",
                Range::mode, Range::modes, Range::ChangeMode
            );
        }
        else
        {
            Settings::timeFrom = UI::InputTimeVar("Minimum evaluation time", TIME_FROM);
        }
        CapMax(TIME_TO, Settings::timeFrom, Settings::timeTo);
        Settings::timeTo = UI::InputTimeVar("Maximum evaluation time", TIME_TO);
    }

    if (UI::CollapsingHeader("Modes"))
    {
        if (ComboHelper("Mode", modeStr, modes, ChangeMode))
        {
            DescribeModes("Modes:", modes, modeMap);
        }

        mode.OnSettings();
    }

    if (UI::CollapsingHeader("Misc"))
    {
        Settings::showInfo = UI::CheckboxVar("Show info during simulation?", SHOW_INFO);
    }
}

void ChangeMode(const string &in newMode)
{
    ModeDispatch(newMode, modeMap, mode);
    SetVariable(MODE, newMode);
    modeStr = newMode;
}
