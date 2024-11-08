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

const string VAR_INPUTS_REACH = VAR + "inputs_reach";
ms varInputsReach;

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

    RegisterVariable(VAR_INPUTS_REACH, 0);

    varLockTimerange  = GetVariableBool(VAR_LOCK_TIMERANGE);
    varEvalBeginStart = ms(GetVariableDouble(VAR_EVAL_BEGIN_START));
    varEvalBeginStop  = ms(GetVariableDouble(VAR_EVAL_BEGIN_STOP));
    varEvalEnd        = ms(GetVariableDouble(VAR_EVAL_END));

    varUseSaveState  = GetVariableBool(VAR_USE_SAVE_STATE);
    varSaveStateName = GetVariableString(VAR_SAVE_STATE_NAME);

    varShowInfo = GetVariableBool(VAR_SHOW_INFO);

    varInputsReach = ms(GetVariableDouble(VAR_INPUTS_REACH));
}

const string INFO_LOCK_TIMERANGE = "Enabling this will set Evaluation Begin Stop Time equal to Evaluation Begin Start Time.";
const string INFO_SHOW_INFO = "Show additional information about the simulation.";
const string INFO_INPUTS_REACH = "When using run-mode bruteforce, what time the last input that needs to be included has.";

void RenderSettings()
{
    Eval::CheckMode();

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

        // UI::Separator();

        // varInputsReach = UI::InputTimeVar("Inputs Reach", VAR_INPUTS_REACH);
        // utils::TooltipOnHover("InputsReach", INFO_INPUTS_REACH);
        // if (UI::Button("Start Run-mode Bruteforce"))
        //     soState = SimOnlyState::INIT;
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
    }

    void OnBegin(SimulationManager@) {}
    void OnStep(SimulationManager@) {}
    void OnEnd(SimulationManager@) {}
}


} // namespace Settings
