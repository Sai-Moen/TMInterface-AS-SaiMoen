namespace Settings
{


const string VAR = ID + "_";

const string VAR_MODE = VAR + "mode";

const string VAR_LOCK_TIMERANGE   = VAR + "lock_timerange";
const string VAR_EVAL_BEGIN_START = VAR + "eval_begin_start";
const string VAR_EVAL_BEGIN_STOP  = VAR + "eval_begin_stop";
const string VAR_EVAL_END         = VAR + "eval_end";

const string VAR_USE_SAVE_STATE  = VAR + "use_save_state";
const string VAR_SAVE_STATE_NAME = VAR + "save_state_name";

const string VAR_SHOW_INFO = VAR + "show_info";

const string VAR_REPLAY_TIME = VAR + "replay_time";

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
}

void RenderSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        const bool mustLockTimerange = !Core::mode.supportsUnlockedTimerange;
        UI::BeginDisabled(mustLockTimerange);
        const bool lockTimerange = UI::CheckboxVar("Lock Timerange", VAR_LOCK_TIMERANGE);
        UI::EndDisabled();

        if (mustLockTimerange)
            TooltipOnHover("The currently selected mode does not support an unlocked timerange.");
        else
            TooltipOnHover("Enabling this will set Evaluation Begin Stop Time equal to Evaluation Begin Start Time.");

        if (UI::Button("Reset timestamps to 0"))
        {
            VarSetMs(VAR_EVAL_BEGIN_START, 0);
            VarSetMs(VAR_EVAL_BEGIN_STOP, 0);
            VarSetMs(VAR_EVAL_END, 0);
        }

        const ms evalBeginStart = UI::InputTimeVar("Evaluation Begin Starting Time", VAR_EVAL_BEGIN_START);
        if (mustLockTimerange || lockTimerange)
        {
            UI::BeginDisabled();
            UI::InputTime("Evaluation Begin Stopping Time", evalBeginStart);
            UI::EndDisabled();
        }
        else
        {
            UI::InputTimeVar("Evaluation Begin Stopping Time", VAR_EVAL_BEGIN_STOP);
        }
        UI::InputTimeVar("Evaluation End Time", VAR_EVAL_END);

        UI::Separator();

        const bool useSaveState = UI::CheckboxVar("Start from Save State", VAR_USE_SAVE_STATE);
        UI::BeginDisabled(!useSaveState);
        UI::InputTextVar("Save State name", VAR_SAVE_STATE_NAME);
        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Modes"))
    {
        ComboHelper("Mode", Core::modeNames, Core::modeIndex, Core::OnModeIndex);
        UI::Separator();

        Core::modeRenderSettings();
    }

    if (UI::CollapsingHeader("Run-Mode"))
    {
        UI::TextWrapped(
            "Run-Mode Bruteforce is an alternative to Simulation,"
            " where the plugin runs during a race rather than on a replay file");

        UI::Separator();

        UI::InputTimeVar("Replay Time", VAR_REPLAY_TIME);
        TooltipOnHover("This is the equivalent to the replay time when using simulation mode.");
        if (UI::Button("Start Run-Mode Bruteforce"))
            soState = SimOnlyState::PRE_INIT;
    }

    if (UI::CollapsingHeader("Misc"))
    {
        UI::CheckboxVar("Show Info", VAR_SHOW_INFO);
        TooltipOnHover("Show additional information about the simulation.");
    }
}

void PrintInfo(const array<InputCommand>@ const commands)
{
    string s;
    s += Core::tInput;
    s += ":\n";

    if (VarGetBool(VAR_SHOW_INFO))
    {
        const float mps = Core::inputState.Dyna.CurrentState.LinearSpeed.Length();

        s += "Speed (km/h): ";
        s += FormatPrecise(mps * 3.6);
        s += "\n";
    }

    for (uint i = 0; i < commands.Length; i++)
    {
        s += commands[i].ToString();
        s += "\n";
    }

    print(s);
}

class Home : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        UI::TextWrapped("Hello!");

        const uint index = Core::GetCurrentModeIndex();
        if (index != 0)
            Core::SetModeIndex(index);
    }

    void OnBegin(SimulationManager@) {}
    void OnStep(SimulationManager@) {}
    void OnEnd(SimulationManager@) {}
}


} // namespace Settings
