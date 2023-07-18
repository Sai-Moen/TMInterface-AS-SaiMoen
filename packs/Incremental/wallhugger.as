// Wallhugger Script

namespace WH
{
    void OnSimulationBegin()
    {
    }

    void OnSimulationStep(SimulationManager@ simManager)
    {
    }
}

class Wallhugger : MScript
{
    const string GetName()
    {
        return "Wallhugger";
    }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
        simManager.RemoveStateValidation();

        WH::OnSimulationBegin();
    }

    void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
    {
        if (userCancelled) return;

        WH::OnSimulationStep(simManager);
    }
}

Wallhugger wh;
