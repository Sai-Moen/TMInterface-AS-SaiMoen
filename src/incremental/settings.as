namespace Settings
{


const string VAR = ID + "_";

const string VAR_MODE = VAR + "mode";

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

const string VAR_REPLAY_TIME = VAR + "replay_time";
ms varReplayTime;

void RegisterSettings()
{
    RegisterVariable(VAR_MODE, "");

    RegisterVariable(VAR_LOCK_TIMERANGE, true);
    RegisterVariable(VAR_EVAL_BEGIN_START, 0);
    RegisterVariable(VAR_EVAL_BEGIN_STOP, 0);
    RegisterVariable(VAR_EVAL_END, 0);

    RegisterVariable(VAR_USE_SAVE_STATE, false);
    RegisterVariable(VAR_SAVE_STATE_NAME, "");

    RegisterVariable(VAR_SHOW_INFO, true);

    RegisterVariable(VAR_REPLAY_TIME, 0);

    varLockTimerange  = GetVariableBool(VAR_LOCK_TIMERANGE);
    varEvalBeginStart = ms(GetVariableDouble(VAR_EVAL_BEGIN_START));
    varEvalBeginStop  = ms(GetVariableDouble(VAR_EVAL_BEGIN_STOP));
    varEvalEnd        = ms(GetVariableDouble(VAR_EVAL_END));

    varUseSaveState  = GetVariableBool(VAR_USE_SAVE_STATE);
    varSaveStateName = GetVariableString(VAR_SAVE_STATE_NAME);

    varShowInfo = GetVariableBool(VAR_SHOW_INFO);

    varReplayTime = ms(GetVariableDouble(VAR_REPLAY_TIME));
}

void RenderSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        const bool lockedTimerange = !Eval::supportsUnlockedTimerange;
        UI::BeginDisabled(lockedTimerange);
        varLockTimerange = UI::CheckboxVar("Lock Timerange", VAR_LOCK_TIMERANGE);
        UI::EndDisabled();
        TooltipOnHover("Enabling this will set Evaluation Begin Stop Time equal to Evaluation Begin Start Time.");

        if (UI::Button("Reset timestamps to 0"))
        {
            SetVariable(VAR_EVAL_BEGIN_START, 0);
            SetVariable(VAR_EVAL_BEGIN_STOP, 0);
            SetVariable(VAR_EVAL_END, 0);
        }

        varEvalBeginStart = UI::InputTimeVar("Evaluation Begin Starting Time", VAR_EVAL_BEGIN_START);
        if (varLockTimerange || lockedTimerange)
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

        UI::Separator();

        varUseSaveState = UI::CheckboxVar("Start from Save State", VAR_USE_SAVE_STATE);
        UI::BeginDisabled(!varUseSaveState);
        varSaveStateName = UI::InputTextVar("Save State name", VAR_SAVE_STATE_NAME);
        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Modes"))
    {
        ComboHelper("Mode", Eval::modeNames, Eval::modeIndex, Eval::OnModeIndex);
        UI::Separator();

        Eval::modeRenderSettings();
    }

    if (UI::CollapsingHeader("Run-Mode"))
    {
        UI::TextWrapped(
            "Run-Mode Bruteforce is an alternative to Simulation,"
            " where the plugin runs during a race rather than on a replay file");

        UI::Separator();

        varReplayTime = UI::InputTimeVar("Replay Time", VAR_REPLAY_TIME);
        TooltipOnHover("This is the equivalent to the replay time when using simulation mode.");
        if (UI::Button("Start Run-Mode Bruteforce"))
            soState = SimOnlyState::PRE_INIT;
    }

    if (UI::CollapsingHeader("Misc"))
    {
        varShowInfo = UI::CheckboxVar("Show Info", VAR_SHOW_INFO);
        TooltipOnHover("Show additional information about the simulation.");
    }
}

void PrintInfo(const array<InputCommand>@ const commands)
{
    StringBuilder builder;
    builder.AppendLine({ Eval::tInput, ":" });

    if (varShowInfo)
    {
        const double kmph = Eval::speed.Length() * 3.6;
        builder.AppendLine({ "Speed (km/h): ", FormatPrecise(kmph) });
    }

    for (uint i = 0; i < commands.Length; i++)
        builder.AppendLine(commands[i].ToString());

    print(builder.ToString().str);
}

class Home : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        UI::TextWrapped("Hello!");

        const uint index = Eval::GetCurrentModeIndex();
        if (index != 0)
            Eval::SetModeIndex(index);
    }

    void OnBegin(SimulationManager@) {}
    void OnStep(SimulationManager@) {}
    void OnEnd(SimulationManager@) {}
}


} // namespace Settings
