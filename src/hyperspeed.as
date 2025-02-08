// Hyper Speed utilities (incl. save state file helpers).

typedef int32 ms;

const string ID = "hyperspeed";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "HyperSpeed";
    info.Version = "v2.1.1a";
    return info;
}

void Main()
{
    Setup();
    RegisterSettingsPage("HyperSpeed", Window);
}

const string VAR = ID + "_";

const string VAR_ENABLED       = VAR + "enabled";
const string VAR_REWIND_TIME   = VAR + "rewind_time";
const string VAR_USE_STATEFILE = VAR + "use_statefile";
const string VAR_FILENAME      = VAR + "filename";
const string VAR_FINISH_TIME   = VAR + "finish_time";

bool enabled;
ms rewindTime;
bool useStateFile;
string filename;
ms finishTime;

SimulationStateFile statefile;
SimulationState@ dummyState;

void Setup()
{
    RegisterVariable(VAR_ENABLED, false);
    RegisterVariable(VAR_REWIND_TIME, 0);
    RegisterVariable(VAR_USE_STATEFILE, false);
    RegisterVariable(VAR_FILENAME, "");
    RegisterVariable(VAR_FINISH_TIME, 0);

    enabled      = GetVariableBool(VAR_ENABLED);
    rewindTime   = ms(GetVariableDouble(VAR_REWIND_TIME));
    useStateFile = GetVariableBool(VAR_USE_STATEFILE);
    filename     = GetVariableString(VAR_FILENAME);
    finishTime   = ms(GetVariableDouble(VAR_FINISH_TIME));

    if (useStateFile && statefile.Load(filename, void))
        @dummyState = statefile.ToState();

    hsState = enabled ? HyperSpeedState::ACTIVE : HyperSpeedState::INACTIVE;
}

enum HyperSpeedState
{
    INACTIVE,

    ACTIVE,
    SPEEDUP,
    GIVEUP,
    FINISH,

    COUNT
}

HyperSpeedState hsState;

void OnRunStep(SimulationManager@ simManager)
{
    const ms time = simManager.RaceTime;
    switch (hsState)
    {
    case HyperSpeedState::ACTIVE:
        if (time < 0)
        {
            if (dummyState is null)
                hsState = HyperSpeedState::SPEEDUP;
            else
                simManager.RewindToState(statefile);
        }
        break;
    case HyperSpeedState::SPEEDUP:
        if (time < 0)
        {
            simManager.SimulationOnly = true;
        }
        else if (time == rewindTime)
        {
            hsState = HyperSpeedState::ACTIVE;
            simManager.SimulationOnly = false;

            if (useStateFile)
            {
                if (statefile.CaptureCurrentState(simManager, true))
                {
                    string error;
                    if (statefile.Save(filename, error))
                        @dummyState = statefile.ToState();
                    else
                        log("Could not save statefile, error: " + error, Severity::Error);
                }
                else
                {
                    log("Could not capture current state!", Severity::Error);
                }
            }
        }
        break;
    case HyperSpeedState::GIVEUP:
        hsState = HyperSpeedState::ACTIVE;
        simManager.GiveUp();
        break;
    case HyperSpeedState::FINISH:
        if (time < 0)
        {
            simManager.SimulationOnly = true;
        }
        else if (time == finishTime)
        {
            hsState = HyperSpeedState::ACTIVE;
            simManager.SimulationOnly = false;
            simManager.ForceFinish();
        }
        break;
    }
}

void Window()
{
    enabled = UI::CheckboxVar("Enable HyperSpeed", VAR_ENABLED);

    const bool disabled = !enabled;
    if (disabled)
        hsState = HyperSpeedState::INACTIVE;
    else if (hsState == HyperSpeedState::INACTIVE)
        hsState = HyperSpeedState::ACTIVE;

    UI::BeginDisabled(disabled);

    rewindTime = UI::InputTimeVar("Rewind Time", VAR_REWIND_TIME);

    UI::Separator();

    useStateFile = UI::CheckboxVar("Use Save State File (.bin)", VAR_USE_STATEFILE);
    const bool noStateFile = !useStateFile;
    if (noStateFile)
        @dummyState = null;

    filename = UI::InputTextVar("Filename", VAR_FILENAME);

    UI::BeginDisabled(noStateFile);

    if (UI::Button("Save statefile to Filename (at Rewind Time)"))
    {
        hsState = HyperSpeedState::GIVEUP;
        @dummyState = null;
    }

    if (UI::Button("Load statefile from Filename"))
    {
        string error;
        if (statefile.Load(filename, error))
            @dummyState = statefile.ToState();
        else
            log("Could not load statefile from '" + filename + "', error: " + error, Severity::Warning);
    }

    UI::EndDisabled();

    if (dummyState is null)
    {
        UI::TextWrapped("No state is loaded");
    }
    else
    {
        const string t = Time::Format(dummyState.PlayerInfo.RaceTime);
        UI::TextWrapped("A state is loaded that starts at " + t);
    }

    UI::Separator();

    finishTime = UI::InputTimeVar("Finish Time", VAR_FINISH_TIME);

    if (UI::Button("Finish at Finish Time"))
        hsState = HyperSpeedState::FINISH;

    UI::EndDisabled();
}
