// Wallhugger Script

namespace WH
{
    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("wh_" + var);
    }

    class Wallhugger : Script
    {
        const string name
        {
            get const { return "Wallhugger"; }
        }

        const string description
        {
            get const { return "Hugs close to a given wall."; }
        }

        void OnRegister() const
        {
        }

        void OnSettings() const
        {
        }

        void OnSimulationBegin(SimulationManager@ simManager) const
        {
        }

        void OnSimulationStep(SimulationManager@ simManager) const
        {
        }
    }
}
