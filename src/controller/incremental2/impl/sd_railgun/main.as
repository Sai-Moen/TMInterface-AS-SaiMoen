namespace SpeedDrift
{


void Main()
{
    RegisterSettings();
    IncRegisterMode("SD Railgun", Mode());
}

class Mode : IncMode
{
    SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings () { SpeedDrift::RenderSettings(); }

    void OnBegin(SimulationManager@ simManager) { SpeedDrift::OnBegin(simManager); }
    void OnStep(SimulationManager@ simManager) { SpeedDrift::OnStep(simManager); }
    void OnEnd(SimulationManager@) {}
}

const string VAR = ::VAR + "sd_";

const string MODE = VAR + "mode";

string modeStr;
array<string> modes;

const Mode@ sdMode;
dictionary sdMap;

void RegisterSettings()
{
    RegisterVariable(MODE, Normal::NAME);

    ModeRegister(sdMap, Normal::mode);
    //ModeRegister(sdMap, Wiggle::mode); // not yet implemented

    modeStr = GetVariableString(MODE);
    ModeDispatch(modeStr, sdMap, sdMode);

    modes = sdMap.GetKeys();
    modes.SortAsc();
}

void RenderSettings()
{
    if (ComboHelper("SD Mode", modeStr, modes, ChangeMode))
    {
        DescribeModes("SD Modes:", modes, sdMap);
    }

    sdMode.OnSettings();
}

void ChangeMode(const string &in newMode)
{
    ModeDispatch(newMode, sdMap, sdMode);
    SetVariable(MODE, newMode);
    modeStr = newMode;
}

void OnBegin(SimulationManager@ simManager)
{
    sdMode.OnBegin(simManager);
}

void OnStep(SimulationManager@ simManager)
{
    sdMode.OnStep(simManager);
}

int steer;
RangeIncl range;

array<int> triedSteers;

int bestSteer;
double bestResult;


} // namespace SpeedDrift
