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

    const float RATE_F = .2f;
}

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER::MIN, STEER::MAX);
}

float ClampTurningRate(const float inputSteer, const float turningRate)
{
    return Math::Clamp(inputSteer, turningRate - STEER::RATE_F, turningRate + STEER::RATE_F);
}

int NextTurningRate(const float inputSteer, const float turningRate)
{
    const float magnitude = ClampTurningRate(inputSteer, turningRate) * STEER::FULL;
    const float direction = magnitude - turningRate * STEER::FULL;
    return RoundAway(magnitude, direction);
}

enum Signum
{
    Negative = -1,
    Zero = 0,
    Positive = 1,
}

Signum Sign(const int num)
{
    return Signum((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

Signum Sign(const float num)
{
    return Signum((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

int RoundAway(const float magnitude, const Signum direction)
{
    switch (direction)
    {
    case Signum::Negative: return int(Math::Floor(magnitude));
    case Signum::Zero: return int(magnitude);
    case Signum::Positive: return int(Math::Ceil(magnitude));
    default: return 0; // Unreachable
    }
}

int RoundAway(const float magnitude, const float direction)
{
    return RoundAway(magnitude, Sign(direction));
}

// API
const string CONTROLLER = "controller";
const string OPEN_EXTERNAL_CONSOLE = "open_external_console";

bool IsOtherController()
{
    return ID != GetVariableString(CONTROLLER);
}

// Script
const string ID = "saimoen_incremental";
const string NAME = "SaiMoen's Incremental module";
const string FILENAME = ID + ".txt";

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

    OnSim@ OnBegin;
    OnSim@ OnStep;

    Mode(
        const string &in _name,
        const string &in _description,
        OnEvent@ const _OnRegister,
        OnEvent@ const _OnSettings,
        OnSim@ const _OnBegin,
        OnSim@ const _OnStep)
    {
        name = _name;
        description = _description;

        @OnRegister = NullCheckHandle(_OnRegister);
        @OnSettings = NullCheckHandle(_OnSettings);

        @OnBegin = NullCheckHandle(_OnBegin);
        @OnStep = NullCheckHandle(_OnStep);
    }
}

OnEvent@ const NullCheckHandle(OnEvent@ const other)
{
    if (other is null)
    {
        return function() {};
    }
    return other;
}

OnSim@ const NullCheckHandle(OnSim@ const other)
{
    if (other is null)
    {
        return function(simManager) {};
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
InputCommand MakeInputCommand(const ms timestamp, const InputType type, const int state)
{
    InputCommand cmd;
    cmd.Timestamp = timestamp;
    cmd.Type = type;
    cmd.State = state;
    return cmd;
}

bool DiffPreviousInput(
    TM::InputEventBuffer@ const buffer,
    const ms time,
    const InputType type,
    bool& current)
{
    const bool new = BufferGetLast(buffer, time, type, current);
    const bool old = current;
    current = new;
    return new != old;
}

bool BufferGetLast(
    TM::InputEventBuffer@ const buffer,
    const ms time,
    const InputType type,
    const bool current)
{
    const auto@ const indices = buffer.Find(time, type);
    if (indices.IsEmpty()) return current;

    return buffer[indices[indices.Length - 1]].Value.Binary;
}

void BufferRemoveAll(
    TM::InputEventBuffer@ const buffer,
    const ms start,
    const ms end,
    const InputType type)
{
    for (ms i = start; i <= end; i += TICK)
    {
        BufferRemoveIndices(buffer, buffer.Find(i, type));
    }
}

void BufferRemoveIndices(TM::InputEventBuffer@ const buffer, const array<uint>@ const indices)
{
    if (indices.IsEmpty()) return;

    const uint len = indices.Length;

    uint contiguous = 1;
    uint old = indices[len - 1];
    for (int i = len - 2; i >= 0; i--)
    {
        const uint new = indices[i];
        if (new == old - 1)
        {
            contiguous++;
        }
        else
        {
            buffer.RemoveAt(old, contiguous);
            contiguous = 1;
        }
        old = new;
    }
    buffer.RemoveAt(old, contiguous);
}

class SteeringRange
{
    int midpoint;
    int Midpoint
    {
        set
        {
            midpoint = value;
            Create();
        }
    }

    uint step;
    uint deviation;
    uint shift;
    bool IsDone { get const { return step <= 1; } }
    bool IsLast { get const { return step < uint(1 << shift); } }

    uint len;
    array<int> range;
    bool IsEmpty { get const { return range.IsEmpty(); } }

    SteeringRange() {}

    SteeringRange(
        const int _midpoint,
        const uint _step,
        const uint _deviation,
        const uint _shift = 1)
    {
        midpoint = _midpoint;
        step = _step;
        deviation = _deviation;
        shift = _shift;

        len = (_deviation / _step + 1) << 1;

        Create();
    }

    void Create()
    {
        int prevL = Math::INT_MAX;
        int prevR = Math::INT_MAX;

        uint i = 0;
        range = array<int>(len);
        for (int offset = deviation; offset > 0; offset -= step)
        {
            const int steerL = ClampSteer(midpoint - offset);
            if (steerL != prevL) range[i++] = steerL;
            prevL = steerL;

            const int steerR = ClampSteer(midpoint + offset);
            if (steerR != prevR) range[i++] = steerR;
            prevR = steerR;
        }
    }

    void Magnify(const int _midpoint)
    {
        midpoint = _midpoint;
        step >>= shift;
        deviation >>= shift;

        Create();
    }

    int Pop()
    {
        int pop = range[0];
        range.RemoveAt(0);
        return pop;
    }
}

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
