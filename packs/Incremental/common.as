// Common Script, defines many common elements or constants.

typedef int ms;
const ms TICK = 10;
const ms TWO_TICKS = TICK << 1;

uint GetTickDiff(const ms start, const ms end)
{
    return (end - start) / TICK;
}

namespace STEER
{
    const int FULL = 0x10000;
    const int HALF = FULL >> 1;
    const int MIN  = -FULL;
    const int MAX  = FULL;

    const int RATE = int(Math::Ceil(FULL * RATE_F));
    const float RATE_F = .2f;
}

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER::MIN, STEER::MAX);
}

int NextTurningRate(const float inputSteer, const float turningRate)
{
    return int(NextTurningRateF(inputSteer, turningRate) * STEER::FULL);
}

float NextTurningRateF(const float inputSteer, const float turningRate)
{
    return Math::Clamp(inputSteer, turningRate - STEER::RATE_F, turningRate + STEER::RATE_F);
}

// API
const string CONTROLLER = "controller";

bool IsOtherController()
{
    return ID != GetVariableString(CONTROLLER);
}

// Script
const string ID = "saimoen_incremental";
const string NAME = "SaiMoen's Incremental module";
const string FILENAME = ID + ".txt";

namespace INFO
{
    const string AUTHOR = "SaiMoen";
    const string NAME = "Incremental module";
    const string DESCRIPTION = "Contains: SD, Wallhug at some point, ...";
    const string VERSION = "v2.0.0.2";
}

// UI utils
funcdef void OnNewMode(const string &in newMode);

bool ComboHelper(
    const string &in label,
    const string &in currentMode,
    const array<string> &in allModes,
    const OnNewMode@ const onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, currentMode);
    if (isOpen)
    {
        for (uint i = 0; i < allModes.Length; i++)
        {
            const string newMode = allModes[i];
            if (UI::Selectable(newMode, currentMode == newMode))
            {
                onNewMode(newMode);
            }
        }

        UI::EndCombo();
    }
    return isOpen;
}

interface Describable
{
    const string Name { get const; }
    const string Description { get const; }
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
        UI::Text(desc.Name + " - " + desc.Description);
    }
    UI::EndTooltip();
}

void CapMax(const string &in variableName, const ms tfrom, const ms tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}

// Dispatch utils
funcdef void OnEvent();
funcdef void OnSim(SimulationManager@ simManager);

class Mode : Describable
{
    string name;
    const string Name { get const { return name; } }

    string description;
    const string Description { get const { return description; } }

    OnEvent@ OnRegister;
    OnEvent@ OnSettings;

    OnSim@ OnSimulationBegin;
    OnSim@ OnSimulationStep;

    Mode(
        const string &in _name,
        const string &in _description,
        OnEvent@ const _OnRegister,
        OnEvent@ const _OnSettings,
        OnSim@ const _OnSimulationBegin,
        OnSim@ const _OnSimulationStep)
    {
        name = _name;
        description = _description;

        @OnRegister = NullCheckHandle(_OnRegister);
        @OnSettings = NullCheckHandle(_OnSettings);

        @OnSimulationBegin = NullCheckHandle(_OnSimulationBegin);
        @OnSimulationStep = NullCheckHandle(_OnSimulationStep);
    }
}

OnEvent@ const NullCheckHandle(OnEvent@ const other)
{
    if (other is null)
    {
        return function(){};
    }
    return other;
}

OnSim@ const NullCheckHandle(OnSim@ const other)
{
    if (other is null)
    {
        return function(simManager){};
    }
    return other;
}

void ModeRegister(
    dictionary& map,
    const Mode@ const handle)
{
    @map[handle.Name] = handle;
    handle.OnRegister();
}

void ModeDispatch(
    const string &in key,
    const dictionary &in map,
    const Mode@& handle)
{
    if (map.Get(key, @handle)) return;

    // If a new version of the script tries to use an old key
    @handle = cast<Mode>(map[map.GetKeys()[0]]);
}

// Special implementation to dispatch to by default
namespace NONE
{
    const string NAME = "None";
    const string DESCRIPTION = "Mainly used for debugging, ignore.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        null, null,
        null, null
    );
}

// General Utils

void log(const uint u, Severity severity = Severity::Info)
{
    log("" + u, severity);
}

void log(const int i, Severity severity = Severity::Info)
{
    log("" + i, severity);
}

void log(const float f, Severity severity = Severity::Info)
{
    log("" + f, severity);
}

void log(const double d, Severity severity = Severity::Info)
{
    log("" + d, severity);
}

void print(const uint u, Severity severity = Severity::Info)
{
    print("" + u, severity);
}

void print(const int i, Severity severity = Severity::Info)
{
    print("" + i, severity);
}

void print(const float f, Severity severity = Severity::Info)
{
    print("" + f, severity);
}

void print(const double d, Severity severity = Severity::Info)
{
    print("" + d, severity);
}

array<int> MakeRangeLen(const int start, const uint len, const uint step = 1)
{
    array<int> range = array<int>(len);
    for (uint i = 0; i < len; i++)
    {
        range[i] = start + step * i;
    }
    return range;
}

array<int> MakeRangeExcl(const int start, const int end, const uint step = 1)
{
    if (start >= end) return array<int>(0);

    const uint len = (end - start) / step;
    return MakeRangeLen(start, len, step);
}

array<int> MakeRangeIncl(const int start, const int end, const uint step = 1)
{
    if (start >= end) return array<int>(0);
    
    const uint len = (end - start) / step + 1;
    return MakeRangeLen(start, len, step);
}
