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

bool enabled;
ms rewindTime;
bool useStateFile;
string filename;

SimulationStateFile statefile;
SimulationState@ dummyState;

void Setup()
{
    RegisterVariable(VAR_ENABLED, false);
    RegisterVariable(VAR_REWIND_TIME, 0);
    RegisterVariable(VAR_USE_STATEFILE, false);
    RegisterVariable(VAR_FILENAME, "");

    enabled      = GetVariableBool(VAR_ENABLED);
    rewindTime   = ms(GetVariableDouble(VAR_REWIND_TIME));
    useStateFile = GetVariableBool(VAR_USE_STATEFILE);
    filename     = GetVariableString(VAR_FILENAME);

    if (useStateFile && statefile.Load(filename, void))
        @dummyState = statefile.ToState();
}

enum HyperSpeedState
{
    INIT,
    SPEEDUP,
    GIVEUP,
}

HyperSpeedState hsState;

void OnRunStep(SimulationManager@ simManager)
{
    if (!enabled)
        return;

    const ms time = simManager.RaceTime;
    switch (hsState)
    {
    case HyperSpeedState::INIT:
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
            hsState = HyperSpeedState::INIT;
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
        hsState = HyperSpeedState::INIT;
        simManager.GiveUp();
        break;
    }
}

void Window()
{
    enabled = UI::CheckboxVar("Enable HyperSpeed", VAR_ENABLED);
    UI::BeginDisabled(!enabled);

    rewindTime = UI::InputTimeVar("Rewind Time", VAR_REWIND_TIME);

    UI::Separator();

    useStateFile = UI::CheckboxVar("Use Save State File (.bin)", VAR_USE_STATEFILE);
    const bool noStateFile = !useStateFile;
    if (noStateFile)
        @dummyState = null;

    filename = UI::InputTextVar("Filename", VAR_FILENAME);

    UI::BeginDisabled(noStateFile);

    if (UI::Button("Save statefile to Filename (at Rewind Time)?"))
    {
        hsState = HyperSpeedState::GIVEUP;
        @dummyState = null;
    }

    if (UI::Button("Load statefile from Filename?"))
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

    UI::EndDisabled();
}
