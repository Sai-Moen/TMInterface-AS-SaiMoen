// Wallhugger Script

class WallHugger : MScript
{
    string name { get const { return "Wallhugger"; } }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
    }

    void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
    {
    }
}

WallHugger wh;
