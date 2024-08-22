namespace Settings
{


const string VAR = ID + "_";

const string VAR_LOCK_TIMERANGE   = VAR + "lock_timerange";
const string VAR_EVAL_BEGIN_START = VAR + "eval_begin_start";
const string VAR_EVAL_BEGIN_STOP  = VAR + "eval_begin_stop";
const string VAR_EVAL_END         = VAR + "eval_end";

bool varLockTimerange;
ms varEvalBeginStart;
ms varEvalBeginStop;
ms varEvalEnd;

const string VAR_USE_SAVE_STATE  = VAR + "use_save_state";
const string VAR_SAVE_STATE_NAME = VAR + "save_state_name";

bool varUseSaveState;
string varSaveStateName;

const string VAR_SHOW_INFO = VAR + "show_info";
bool varShowInfo;

void RegisterSettings()
{
    RegisterVariable(VAR_LOCK_TIMERANGE, true);
    RegisterVariable(VAR_EVAL_BEGIN_START, 0);
    RegisterVariable(VAR_EVAL_BEGIN_STOP, 0);
    RegisterVariable(VAR_EVAL_END, 0);

    RegisterVariable(VAR_USE_SAVE_STATE, false);
    RegisterVariable(VAR_SAVE_STATE_NAME, "");

    RegisterVariable(VAR_SHOW_INFO, true);

    varLockTimerange = GetVariableBool(VAR_LOCK_TIMERANGE);
    varEvalBeginStart = ms(GetVariableDouble(VAR_EVAL_BEGIN_START));
    varEvalBeginStop = ms(GetVariableDouble(VAR_EVAL_BEGIN_STOP));
    varEvalEnd = ms(GetVariableDouble(VAR_EVAL_END));

    varUseSaveState = GetVariableBool(VAR_USE_SAVE_STATE);
    varSaveStateName = GetVariableString(VAR_SAVE_STATE_NAME);

    varShowInfo = GetVariableBool(VAR_SHOW_INFO);
}

void RenderSettings()
{
    utils::ComboHelper("Modes:", modeIndex, modeNames, OnModeIndex);

    if (UI::CollapsingHeader("General"))
    {
        varLockTimerange = UI::CheckboxVar("Lock Timerange?", VAR_LOCK_TIMERANGE);
        UI::TextDimmed("Enabling this will set Evaluation Begin Stop Time equal to Evaluation Begin Start Time.");

        varEvalBeginStart = UI::InputTimeVar("Evaluation Begin Starting Time", VAR_EVAL_BEGIN_START);
        if (varLockTimerange || !supportsUnlockedTimerange)
        {
            UI::BeginDisabled();
            varEvalBeginStop = UI::InputTime("Evaluation Begin Stopping Time", varEvalBeginStart);
            UI::EndDisabled();
        }
        else
        {
            varEvalBeginStop = UI::InputTimeVar("Evaluation Begin Stopping Time", VAR_EVAL_BEGIN_STOP);
        }
        varEvalEnd = UI::InputTimeVar("Evaluation End Time", VAR_EVAL_END);

        UI:Separator();

        UI::BeginDisabled(!supportsSaveStates);

        varUseSaveState = UI::CheckboxVar("Start from Save State?", VAR_USE_SAVE_STATE);
        UI::BeginDisabled(!varUseSaveState);
        varSaveStateName = UI::InputTextVar("Save State name", VAR_SAVE_STATE_NAME);
        UI::EndDisabled();

        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Modes"))
    {
        modeRenderSettings();
    }

    if (UI::CollapsingHeader("Misc"))
    {
        varShowInfo = UI::CheckboxVar("Show Info?", VAR_SHOW_INFO);
        UI::TextDimmed("Shows additional information about the simulation.");
    }
}

void OnModeIndex(const uint newIndex)
{
    modeIndex = newIndex;

    const uint len = modes.Length;
    if (modeIndex < len)
        ModeDispatch();
    else
        log("Mode Index somehow went out of bounds... (" + modeIndex + " >= " + len + ")");
}

void ModeDispatch()
{
    IncMode@ imode = modes[modeIndex];

    supportsSaveStates = imode.SupportsSaveStates;
    supportsUnlockedTimerange = imode.SupportsUnlockedTimerange;

    @modeRenderSettings = imode.RenderSettings;

    @modeOnBegin = imode.OnBegin;
    @modeOnStep = imode.OnStep;
    @modeOnEnd = imode.OnEnd;
}

class Home : IncMode
{
    bool SupportsSaveStates { get { return true; } }
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        UI::TextWrapped("Hello!");
    }

    void OnBegin(SimulationManager@) {}
    void OnStep(SimulationManager@) {}
    void OnEnd(SimulationManager@) {}
}


} // namespace Settings
