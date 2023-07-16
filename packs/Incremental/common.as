// Common Script, Defines many common elements or constants.

// API constants/vars

const string CONTROLLER = "controller";

// Script constants

const string ID = "saimoen_incremental";
const string NAME = "SaiMoen's Incremental pack";

const string INFO_NAME = "Incremental pack";
const string INFO_AUTHOR = "SaiMoen";
const string INFO_VERSION = "v1.5.0";
const string INFO_DESCRIPTION = "Contains: SD, Wallhug, ...";

const int TICK_MS = 10;
const int SEEK_MS = 120;

// Script Dispatch

dictionary funcMap;
const ScriptFuncs@ funcs;

ScriptFuncs GetScriptFuncs(string key)
{
    return cast<ScriptFuncs>(funcMap[key]);
}

funcdef void Settings();
funcdef void SimBegin(SimulationManager@ simManager);
funcdef void SimStep(SimulationManager@ simManager, bool userCancelled);

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
        funcMap[name] = @ScriptFuncs(
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

    void OnSimulationBegin(SimulationManager@ simManager)
    {
    }

    void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
    {
    }
}

// Special implementation to dispatch to by default

class None : MScript
{
    string name { get const { return "None"; } }
}

None none;
