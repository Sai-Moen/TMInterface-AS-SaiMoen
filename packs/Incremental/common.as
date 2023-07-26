// Common Script, defines many common elements or constants.

// Game constants
typedef int ms;
const ms TICK = 10;
const ms TWO_TICKS = TICK << 1;

// API constants/vars
const string CONTROLLER = "controller";

funcdef void SimStep(SimulationManager@ simManager, bool userCancelled);
const SimStep@ step;

// Script constants
const string ID = "saimoen_incremental";
const string NAME = "SaiMoen's Incremental pack";

const string INFO_NAME = "Incremental pack";
const string INFO_AUTHOR = "SaiMoen";
const string INFO_VERSION = "v1.5.0";
const string INFO_DESCRIPTION = "Contains: SD, Wallhug, ...";

// Script Dispatch
dictionary scriptMap;
const Script@ script;

void ScriptDispatch(const string key = mode)
{
    if (scriptMap.Get(key, @script)) return;

    // Should only come up while debugging, not in release!
    log("Cannot dispatch to: " + key, Severity::Error);
    @script = cast<Script>(scriptMap[MODE_NONE]);
}

void ScriptRegister(const Script@ const script)
{
    @scriptMap[script.GetName()] = script;
    script.OnRegister();
}

void DescribeModes(
    const string &in label,
    const array<string> &in modes,
    const dictionary &in map)
{
    UI::BeginTooltip();
    UI::Text(label);
    for (uint i = 0; i < modes.Length; i++)
    {
        const Describable@ desc = cast<Describable>(map[modes[i]]);
        UI::Text(desc.GetName() + " - " + desc.GetDescription());
    }
    UI::EndTooltip();
}

interface Describable
{
    const string GetName() const;
    const string GetDescription() const;
}

interface Script : Describable
{
    void OnRegister() const;
    void OnSettings() const;

    void OnSimulationBegin(SimulationManager@ simManager) const;
    void OnSimulationStep(SimulationManager@ simManager) const;
}

// Special implementation to dispatch to by default
class None : Script
{
    const string GetName() const
    {
        return MODE_NONE;
    }

    const string GetDescription() const
    {
        return "Mainly used for debugging, ignore.";
    }

    void OnRegister() const {}
    void OnSettings() const {}

    void OnSimulationBegin(SimulationManager@ simManager) const {}
    void OnSimulationStep(SimulationManager@ simManager) const {}
}
