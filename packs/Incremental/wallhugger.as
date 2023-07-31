// Wallhugger Script

namespace WH
{
    const string NAME = "Wallhugger";
    const string DESCRIPTION = "Hugs close to a given wall.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnSimulationBegin, OnSimulationStep
    );

    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("wh_" + var);
    }

    void OnRegister()
    {
    }

    void OnSettings()
    {
    }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
    }

    void OnSimulationStep(SimulationManager@ simManager)
    {
    }
}
