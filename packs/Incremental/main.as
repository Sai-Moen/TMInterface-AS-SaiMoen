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

    RegisterUI();

    RegisterValidationHandler(
        ID, NAME,
        @RenderValidationHandlerSettings(DrawSettings)
    );
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    string controller = GetVariableString(CONTROLLER);
    if (controller != ID)
    {
        @funcs = GetScriptFuncs(none.name);
    }

    funcs.begin(simManager);
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    funcs.step(simManager, userCancelled);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
}
