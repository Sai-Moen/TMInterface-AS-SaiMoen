namespace SpeedDrift::Wiggle
{


const string NAME = "Wiggle";

const string VAR = SpeedDrift::VAR + "wiggle_";

void RegisterSettings()
{}

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        UI::TextWrapped("Sorry! Not yet available...");
    }

    void OnBegin(SimulationManager@)
    {}

    void OnStep(SimulationManager@)
    {}

    void OnEnd(SimulationManager@)
    {}
}


} // namespace SpeedDrift::Wiggle
