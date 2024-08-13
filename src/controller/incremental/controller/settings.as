const string PREFIX = ID + "_";

const string MODE = PREFIX + "mode";

const string EVAL_RANGE = PREFIX + "eval_range";
const string EVAL_TO    = PREFIX + "eval_to";
const string TIME_FROM  = PREFIX + "time_from";
const string TIME_TO    = PREFIX + "time_to";

const string USE_SAVE_STATE =  PREFIX + "use_save_state";
const string SAVE_STATE_NAME = PREFIX + "save_state_name";

const string SHOW_INFO = PREFIX + "show_info";

string modeStr;
array<string> modes;

namespace Settings
{
    bool evalRange;
    ms evalTo;
    ms timeFrom;
    ms timeTo;

    bool useSaveState;
    string saveStateName;
    void TryLoadStateFile(SimulationManager@ simManager)
    {
        auto@ const statefile = SimulationStateFile();
        string error;
        if (statefile.Load(saveStateName, error))
        {
            simManager.RewindToState(statefile.ToState());
        }
        else
        {
            print("There was an error with the savestate:", Severity::Error);
            print(error, Severity::Error);
        }
    }

    bool showInfo;
    void PrintInfo(SimulationState@ state, const string &in script)
    {
        string printable = script;
        if (showInfo)
        {
            const string kmph = PreciseFormat(state.Dyna.CurrentState.LinearSpeed.Length() * 3.6);
            printable += " -> " + kmph + " km/h";
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

    RegisterVariable(USE_SAVE_STATE, false);
    RegisterVariable(SAVE_STATE_NAME, "");

    RegisterVariable(Range::MODE, Range::modes[0]);

    RegisterVariable(SHOW_INFO, true);

    // Register sub-modes
    ModeRegister(modeMap, NONE::mode);

    ModeRegister(modeMap, SD::mode);
    ModeRegister(modeMap, WH::mode);
    ModeRegister(modeMap, SI::mode);

    // Init
    modeStr = GetVariableString(MODE);
    ModeDispatch(modeStr, modeMap, mode);

    modes = modeMap.GetKeys();
    modes.SortAsc();

    Settings::evalRange = GetVariableBool(EVAL_RANGE);
    Settings::evalTo    = ms(GetVariableDouble(EVAL_TO));
    Settings::timeFrom  = ms(GetVariableDouble(TIME_FROM));
    Settings::timeTo    = ms(GetVariableDouble(TIME_TO));

    Settings::useSaveState  = GetVariableBool(USE_SAVE_STATE);
    Settings::saveStateName = GetVariableString(SAVE_STATE_NAME);

    Range::mode = GetVariableString(Range::MODE);
    Range::ChangeMode(Range::mode);

    Settings::showInfo = GetVariableBool(SHOW_INFO);
}

void OnSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        if (Settings::evalRange = UI::CheckboxVar("Evaluate timerange?", EVAL_RANGE))
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
        Settings::timeTo = UI::InputTimeVar("Maximum evaluation time", TIME_TO);

        if (Settings::useSaveState = UI::CheckboxVar("Use savestate?", USE_SAVE_STATE))
        {
            Settings::saveStateName = UI::InputTextVar("Filename", SAVE_STATE_NAME);
        }
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
