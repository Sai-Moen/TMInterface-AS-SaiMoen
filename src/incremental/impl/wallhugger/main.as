namespace Wallhugger
{


void Main()
{
    modeNames = { Classic::NAME, Normal::NAME };
    modes = { Classic::Mode(), Normal::Mode() };

    RegisterSettings();
    IncRegisterMode("Wallhugger", Mode());
}

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return supportsUnlockedTimerange; } }

    void RenderSettings()
    {
        ComboHelper("Wallhug Mode", modeNames, modeIndex, OnModeIndex);
        UI::Separator();

        modeRenderSettings();
    }

    void OnBegin(SimulationManager@ simManager)
    {
        IncRemoveSteeringAhead(simManager);
        modeOnBegin(simManager);
    }

    void OnStep(SimulationManager@ simManager)
    {
        modeOnStep(simManager);
    }

    void OnEnd(SimulationManager@)
    {}
}

const string VAR = Settings::VAR + "wh_";

const string MODE = VAR + "mode";

uint modeIndex;
array<string> modeNames;
array<IncMode@> modes;

bool supportsUnlockedTimerange;

funcdef void OnEvent();
OnEvent@ modeRenderSettings;

funcdef void OnSim(SimulationManager@);
OnSim@ modeOnBegin;
OnSim@ modeOnStep;
OnSim@ modeOnEnd;

void RegisterSettings()
{
    RegisterVariable(MODE, Classic::NAME);
    const string mode = GetVariableString(MODE);
    const int index = modeNames.Find(mode);
    modeIndex = index == -1 ? 0 : index;

    Classic::RegisterSettings();
    Normal::RegisterSettings();
    ModeDispatch();
}

void OnModeIndex(const uint newIndex)
{
    modeIndex = newIndex;

    const uint len = modes.Length;
    if (modeIndex < len)
        ModeDispatch();
    else
        log("Mode Index somehow went out of bounds... (" + modeIndex + " >= " + len + ")", Severity::Warning);
}

void ModeDispatch()
{
    SetVariable(MODE, modeNames[modeIndex]);
    IncMode@ const imode = modes[modeIndex];

    supportsUnlockedTimerange = imode.SupportsUnlockedTimerange;

    @modeRenderSettings = OnEvent(imode.RenderSettings);

    @modeOnBegin = OnSim(imode.OnBegin);
    @modeOnStep = OnSim(imode.OnStep);
    @modeOnEnd = OnSim(imode.OnEnd);
}

// reusable
int steer;


} // namespace Wallhugger
