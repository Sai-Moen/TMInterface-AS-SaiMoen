// Common Script, defines many common elements or constants.

// Game
typedef int ms;
const ms TICK = 10;
const ms TWO_TICKS = TICK << 1;

const int FULLSTEER = 0x10000;
const int STEER_MIN = -FULLSTEER;
const int STEER_MAX = FULLSTEER;
const int STEER_RATE = int(Math::Ceil(FULLSTEER / 5.f));

// API
const string CONTROLLER = "controller";

funcdef void OnSimStep(SimulationManager@ simManager, bool userCancelled);
const OnSimStep@ step;

// Script
const string ID = "saimoen_incremental";
const string NAME = "SaiMoen's Incremental pack";
const string FILENAME = ID + ".txt";

const string INFO_NAME = "Incremental pack";
const string INFO_AUTHOR = "SaiMoen";
const string INFO_VERSION = "v1.5.0";
const string INFO_DESCRIPTION = "Contains: SD, Wallhug, ...";

// Dispatch
dictionary scriptMap;
const Script@ script;

interface Describable
{
    const string name { get const; }
    const string description { get const; }
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
        const Describable@ const desc = cast<Describable>(map[modes[i]]);
        UI::Text(desc.name + " - " + desc.description);
    }
    UI::EndTooltip();
}

interface Script : Describable
{
    void OnRegister() const;
    void OnSettings() const;

    void OnSimulationBegin(SimulationManager@ simManager) const;
    void OnSimulationStep(SimulationManager@ simManager) const;
}

void ScriptRegister(
    dictionary& map,
    const Script@ const handle)
{
    @map[handle.name] = handle;
    handle.OnRegister();
}

bool ScriptDispatch(
    const string &in key,
    const dictionary &in map,
    const Script@& handle)
{
    return map.Get(key, @handle);
}

interface ScriptClass : Describable
{
    void OnRegister();
    void OnSettings();

    void OnSimulationBegin(SimulationManager@ simManager);
    void OnSimulationStep(SimulationManager@ simManager);
}

void ScriptClassRegister(
    dictionary& map,
    ScriptClass@ const handle)
{
    @map[handle.name] = handle;
    handle.OnRegister();
}

bool ScriptClassDispatch(
    const string &in key,
    const dictionary &in map,
    const ScriptClass@& handle)
{
    return map.Get(key, @handle);
}

// Special implementation to dispatch to by default
class None : Script
{
    const string name
    {
        get const { return MODE_NONE; }
    }

    const string description
    {
        get const { return "Mainly used for debugging, ignore."; }
    }

    void OnRegister() const {}
    void OnSettings() const {}

    void OnSimulationBegin(SimulationManager@ simManager) const {}
    void OnSimulationStep(SimulationManager@ simManager) const {}
}
