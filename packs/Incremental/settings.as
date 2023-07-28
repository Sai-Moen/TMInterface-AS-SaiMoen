// Settings/vars/ui Script, extension of common

const string PrefixVar(const string &in var)
{
    return "saimoen_" + var;
}

const string MODE       = PrefixVar("mode");
const string MODE_NONE = "None";

const string EVAL_RANGE = PrefixVar("eval_range");
const string EVAL_TO    = PrefixVar("eval_to");
const string TIME_FROM  = PrefixVar("time_from");
const string TIME_TO    = PrefixVar("time_to");

enum Direction
{
    left,
    right,
}

string mode;
array<string> modes;

bool evalRange;
ms evalTo;
ms timeFrom;
ms timeTo;

void OnRegister()
{
    // Register
    RegisterVariable(MODE, MODE_NONE);

    RegisterVariable(EVAL_RANGE, false);
    RegisterVariable(EVAL_TO, 0);
    RegisterVariable(TIME_FROM, 0);
    RegisterVariable(TIME_TO, 10000);

    // Register sub-modes
    ScriptRegister(scriptMap, None());

    ScriptRegister(scriptMap, SD::SDRailgun());
    ScriptRegister(scriptMap, WH::Wallhugger());

    // Init
    mode = GetVariableString(MODE);
    ScriptDispatch(mode, scriptMap, script);

    modes = scriptMap.GetKeys();
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
            evalTo = UI::InputTimeVar("Maximum evaluation time", EVAL_TO);
            CapMax(EVAL_TO, timeFrom, evalTo);
            CapMax(TIME_TO, evalTo, timeTo);
        }
        else
        {
            timeFrom = UI::InputTimeVar("Time to start at", TIME_FROM);
        }
        timeTo = UI::InputTimeVar("Time to stop at", TIME_TO);
        CapMax(TIME_TO, timeFrom, timeTo);
    }

    if (UI::CollapsingHeader("Modes"))
    {
        if (ComboHelper("Mode", mode, modes, ChangeMode))
        {
            DescribeModes("Modes:", modes, scriptMap);
        }

        UI::Separator();

        script.OnSettings();
    }
}

void CapMax(const string &in variableName, const ms tfrom, const ms tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}

void ChangeMode(const string &in newMode)
{
    ScriptDispatch(newMode, scriptMap, script);
    SetVariable(MODE, newMode);
    mode = newMode;
}

funcdef void OnNewMode(const string &in newMode);

bool ComboHelper(
    const string &in label,
    const string &in currentMode,
    const array<string> &in allModes,
    const OnNewMode@ const onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, currentMode);
    if (isOpen)
    {
        for (uint i = 0; i < allModes.Length; i++)
        {
            const string newMode = allModes[i];
            if (UI::Selectable(newMode, currentMode == newMode))
            {
                onNewMode(newMode);
            }
        }

        UI::EndCombo();
    }
    return isOpen;
}
