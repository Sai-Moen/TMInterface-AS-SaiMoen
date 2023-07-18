// Common Script, Defines many common elements or constants.

// Game constants
const int TICK_MS = 10;

// API constants/vars
const string CONTROLLER = "controller";

funcdef void SimBegin(SimulationManager@ simManager);
funcdef void SimStep(SimulationManager@ simManager, bool userCancelled);

// Script constants
const string ID = "saimoen_incremental";
const string NAME = "SaiMoen's Incremental pack";

const string INFO_NAME = "Incremental pack";
const string INFO_AUTHOR = "SaiMoen";
const string INFO_VERSION = "v1.5.0";
const string INFO_DESCRIPTION = "Contains: SD, Wallhug, ...";

// Script Dispatch
dictionary funcMap;
array<string> modes;
const ScriptFuncs@ funcs;

funcdef void Settings();

const ScriptFuncs@ GetScriptFuncs(string key)
{
    return cast<ScriptFuncs@>(funcMap[key]);
}

class ScriptFuncs
{
    ScriptFuncs(
        const Settings@ const _settings,
        const SimBegin@ const _begin,
        const SimStep@ const _step)
    {
        @settings = @_settings;
        @begin = @_begin;
        @step = @_step;
    }

    const Settings@ settings;
    const SimBegin@ begin;
    const SimStep@ step;
}

mixin class MScript
{
    void RegisterFuncs() final
    {
        funcMap[GetName()] = @ScriptFuncs(
            @Settings(OnSettings),
            @SimBegin(OnSimulationBegin),
            @SimStep(OnSimulationStep)
        );

        RegisterVars();
    }

    // Ignore by default
    void RegisterVars()
    {
    }

    void OnSettings()
    {
    }
}

// Special implementation to dispatch to by default
const string MODE_NONE = "None";

class None : MScript
{
    const string GetName()
    {
        return MODE_NONE;
    }

    void OnSimulationBegin(SimulationManager@ simManager)
    {
    }

    void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
    {
    }
}

None none;
