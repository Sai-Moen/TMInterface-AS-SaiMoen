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

const string INFO_LOCK_TIMERANGE = "Enabling this will set Evaluation Begin Stop Time equal to Evaluation Begin Start Time.";
const string INFO_SHOW_INFO = "Show additional information about the simulation.";

void RenderSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        const bool lockedTimerange = !Eval::supportsUnlockedTimerange;
        UI::BeginDisabled(lockedTimerange);
        varLockTimerange = UI::CheckboxVar("Lock Timerange", VAR_LOCK_TIMERANGE);
        UI::EndDisabled();
        utils::TooltipOnHover("LockTimeRange", INFO_LOCK_TIMERANGE);

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
        utils::ComboHelper("Mode", Eval::modeIndex, Eval::modeNames, Eval::OnModeIndex);
        UI::Separator();

        Eval::modeRenderSettings();
    }

    if (UI::CollapsingHeader("Misc"))
    {
        varShowInfo = UI::CheckboxVar("Show Info", VAR_SHOW_INFO);
        utils::TooltipOnHover("ShowInfo", INFO_SHOW_INFO);
    }
}

const string INFO_RUN_MODE_NOTE =
    "Note: this is the run-mode settings page for Incremental.\n"
    "For the actual settings, select the Incremental validation handler.";
const string INFO_REPLAY_TIME = "This is the equivalent to the replay time when using simulation mode.";

void RenderRunMode()
{
    UI::TextWrapped(INFO_RUN_MODE_NOTE);

    UI::Separator();

    varReplayTime = UI::InputTimeVar("Replay Time", VAR_REPLAY_TIME);
    utils::TooltipOnHover("ReplayTime", INFO_REPLAY_TIME);
    if (UI::Button("Start Run-Mode Bruteforce"))
        soState = SimOnlyState::PRE_INIT;
}

void PrintInfo(const array<InputCommand>@ const commands)
{
    string builder;
    builder.Resize(128);
    uint pos = 0;

    const string t = Eval::tInput + ":\n";
    builder.Insert(pos, t);
    pos += t.Length;

    if (varShowInfo)
    {
        const double kmph = Eval::speed.Length() * 3.6;
        const string speed = "Speed (km/h):" + utils::PreciseFormat(kmph) + "\n";
        builder.Insert(pos, speed);
        pos += speed.Length;
    }

    const uint len = commands.Length;
    for (uint i = 0; i < len; i++)
    {
        const string command = commands[i].ToString() + "\n";
        builder.Insert(pos, command);
        pos += command.Length;
    }

    builder.Erase(pos);
    print(builder);
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
