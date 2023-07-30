// Common Script, defines many common elements or constants.

// Game
typedef int ms;
const ms TICK = 10;
const ms TWO_TICKS = TICK << 1;

const int FULLSTEER = 0x10000;
const int STEER_MIN = -FULLSTEER;
const int STEER_MAX = FULLSTEER;

const float STEER_RATE_F = .2f;
const int STEER_RATE = int(Math::Ceil(FULLSTEER * STEER_RATE_F));

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER_MIN, STEER_MAX);
}

float NextTurningRate(const float inputSteer, const float turningRate)
{
    return Math::Clamp(inputSteer, turningRate - STEER_RATE_F, turningRate + STEER_RATE_F);
}

// API
const string CONTROLLER = "controller";

// Script
const string ID = "saimoen_incremental";
const string NAME = "SaiMoen's Incremental pack";
const string FILENAME = ID + ".txt";

const string INFO_NAME = "Incremental pack";
const string INFO_AUTHOR = "SaiMoen";
const string INFO_VERSION = "v1.5.0";
const string INFO_DESCRIPTION = "Contains: SD, Wallhug, ...";

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

bool ModeDispatch(
    const string &in key,
    const dictionary &in map,
    const Mode@& handle)
{
    return map.Get(key, @handle);
}

// Special implementation to dispatch to by default
const string MODE_NONE_NAME = "None";
const string MODE_NONE_DESCRIPTION = "Mainly used for debugging, ignore.";
const Mode@ const none = Mode(
    MODE_NONE_NAME, MODE_NONE_DESCRIPTION,
    null, null,
    null, null
);

// General Utils

void MakeRange(const uint size = 0) {}

array<int> MakeRangeExcl(const int start, const int end, const uint step = 1)
{
    if (start >= end) return array<int>(0);

    uint len = (end - start) / step;
    auto range = array<int>(len);
    for (uint i = 0; i < len; i++)
    {
        range[i] = start + step * i;
    }
    return range;
}

array<int> MakeRangeIncl(const int start, const int end, const uint step = 1)
{
    if (start >= end) return array<int>(0);
    
    uint len = (end - start) / step + 1;
    auto range = array<int>(len);
    for (uint i = 0; i < len; i++)
    {
        range[i] = start + step * i;
    }
    return range;
}
