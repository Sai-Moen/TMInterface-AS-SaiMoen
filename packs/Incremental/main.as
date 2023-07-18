// Main Script, Strings everything together

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.name = INFO_NAME;
    info.author = INFO_AUTHOR;
    info.version = INFO_VERSION;
    info.description = INFO_DESCRIPTION;
    return info;
}

void Main()
{
    // Order matters
    none.RegisterFuncs();

    sd.RegisterFuncs();
    wh.RegisterFuncs();

    SetupSettings();

    RegisterValidationHandler(ID, NAME, DrawSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    // Do not execute unless we are the controller
    string controller = GetVariableString(CONTROLLER);
    if (controller != ID)
    {
        @funcs = GetScriptFuncs(MODE_NONE);
    }

    funcs.begin(simManager);
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    funcs.step(simManager, userCancelled);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    string mode = GetVariableString(MODE);
    @funcs = GetScriptFuncs(mode);
}
