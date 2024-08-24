namespace Wallhugger
{


void Main()
{
    RegisterSettings();
    IncRegisterMode("Wallhugger", Mode());
}

class Mode : IncMode
{
    SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings() { Wallhugger::RenderSettings(); }

    void OnBegin(SimulationManager@ simManager) { Wallhugger::OnBegin(simManager); }
    void OnStep(SimulationManager@ simManager) { Wallhugger::OnStep(simManager); }
    void OnEnd(SimulationManager@) {}
}

const string VAR = ::VAR + "wh_";

const string MODE = VAR + "mode";

string modeStr;
array<string> modes;

const Mode@ whMode;
dictionary whMap;

void OnRegister()
{
    RegisterVariable(MODE, Classic::NAME);

    ModeRegister(whMap, Classic::mode);
    ModeRegister(whMap, Normal::mode);

    modeStr = GetVariableString(MODE);
    ModeDispatch(modeStr, whMap, whMode);

    modes = whMap.GetKeys();
    modes.SortAsc();
}

void OnSettings()
{
    if (ComboHelper("Wallhug Mode", modeStr, modes, ChangeMode))
    {
        DescribeModes("Wallhug Modes:", modes, whMap);
    }

    whMode.OnSettings();
}

void ChangeMode(const string &in newMode)
{
    ModeDispatch(newMode, whMap, whMode);
    SetVariable(MODE, newMode);
    modeStr = newMode;
}

void OnBegin(SimulationManager@ simManager)
{
    whMode.OnBegin(simManager);
}

void OnStep(SimulationManager@ simManager)
{
    whMode.OnStep(simManager);
}

int steer;


} // namespace Wallhugger
