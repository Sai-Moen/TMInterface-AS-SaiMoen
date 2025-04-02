namespace SpeedDrift
{


void Main()
{
    modeNames = { Normal::NAME, Wiggle::NAME };
    modes = { Normal::Mode(), Wiggle::Mode() };

    RegisterSettings();
    IncRegisterMode("SD Railgun", Mode());
}

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return supportsUnlockedTimerange; } }

    void RenderSettings()
    {
        ComboHelper("SD Mode", modeNames, modeIndex, OnModeIndex);
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

const string VAR = Settings::VAR + "sd_";

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
    RegisterVariable(MODE, Normal::NAME);
    const string mode = GetVariableString(MODE);
    const int index = modeNames.Find(mode);
    modeIndex = index == -1 ? 0 : index;

    Normal::RegisterSettings();
    Wiggle::RegisterSettings();
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
int bound;

array<int> triedSteers;

int bestSteer;
double bestResult;


} // namespace SpeedDrift
