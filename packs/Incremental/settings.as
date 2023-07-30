// Settings/vars/ui Script, extension of common

const string PrefixVar(const string &in var)
{
    return "saimoen_" + var;
}

const string MODE       = PrefixVar("mode");

const string EVAL_RANGE = PrefixVar("eval_range");
const string EVAL_TO    = PrefixVar("eval_to");
const string TIME_FROM  = PrefixVar("time_from");
const string TIME_TO    = PrefixVar("time_to");

string modeStr;
array<string> modes;

bool evalRange;
ms evalTo;
ms timeFrom;
ms timeTo;

void OnRegister()
{
    // Register
    RegisterVariable(MODE, MODE_NONE_NAME);

    RegisterVariable(EVAL_RANGE, false);
    RegisterVariable(EVAL_TO, 0);
    RegisterVariable(TIME_FROM, 0);
    RegisterVariable(TIME_TO, 10000);

    // Register sub-modes
    ModeRegister(modeMap, none);

    ModeRegister(modeMap, SD::mode);
    ModeRegister(modeMap, WH::mode);

    // Init
    modeStr = GetVariableString(MODE);
    ModeDispatch(modeStr, modeMap, mode);

    modes = modeMap.GetKeys();
    modes.SortAsc();

    evalRange = GetVariableBool(EVAL_RANGE);
    evalTo    = ms(GetVariableDouble(EVAL_TO));
    timeFrom  = ms(GetVariableDouble(TIME_FROM));
    timeTo    = ms(GetVariableDouble(TIME_TO));
}

void OnSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        evalRange = UI::CheckboxVar("Evaluate timerange?", EVAL_RANGE);
        if (evalRange)
        {
            timeFrom = UI::InputTimeVar("Minimum evaluation time", TIME_FROM);
            CapMax(EVAL_TO, timeFrom, evalTo);
            evalTo = UI::InputTimeVar("Maximum evaluation time", EVAL_TO);
            CapMax(TIME_TO, evalTo, timeTo);
        }
        else
        {
            timeFrom = UI::InputTimeVar("Time to start at", TIME_FROM);
        }
        CapMax(TIME_TO, timeFrom, timeTo);
        timeTo = UI::InputTimeVar("Time to stop at", TIME_TO);
    }

    if (UI::CollapsingHeader("Modes"))
    {
        if (ComboHelper("Mode", modeStr, modes, ChangeMode))
        {
            DescribeModes("Modes:", modes, modeMap);
        }

        UI::Separator();

        mode.OnSettings();
    }
}

void ChangeMode(const string &in newMode)
{
    ModeDispatch(newMode, modeMap, mode);
    SetVariable(MODE, newMode);
    modeStr = newMode;
}

void CapMax(const string &in variableName, const ms tfrom, const ms tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}
