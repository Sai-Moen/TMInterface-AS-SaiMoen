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
}

int ToSteer(const float small)
{
    return int(small * STEER::FULL);
}

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER::MIN, STEER::MAX);
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
string PreciseFormat(const double value)
{
    return Text::FormatFloat(value, " ", 0, 6);
}

InputCommand MakeInputCommand(const ms timestamp, const InputType type, const int state)
{
    InputCommand cmd;
    cmd.Timestamp = timestamp;
    cmd.Type = type;
    cmd.State = state;
    return cmd;
}

// buffer
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

int BufferGetLast(
    TM::InputEventBuffer@ const buffer,
    const ms time,
    const InputType type,
    const int current)
{
    const auto@ const indices = buffer.Find(time, type);
    if (indices.IsEmpty()) return current;

    return buffer[indices[indices.Length - 1]].Value.Analog;
}

array<array<uint>@>@ BufferGetAllIndices(
    TM::InputEventBuffer@ const buffer,
    const ms start, const ms end,
    const InputType type, uint &out lenTotal)
{
    lenTotal = 0;
    array<array<uint>@> indexArrayArray;

    for (ms t = start; t <= end; t += TICK)
    {
        auto@ const indexArray = buffer.Find(t, type);
        lenTotal += indexArray.Length;
        indexArrayArray.Add(indexArray);
    }
    return indexArrayArray;
}

void BufferRemoveAll(
    TM::InputEventBuffer@ const buffer,
    const ms start, const ms end,
    const InputType type)
{
    if (start > end)
        return;

    uint lenTotal;
    const auto@ const indexArrayArray = BufferGetAllIndices(buffer, start, end, type, lenTotal);

    const auto@ const indices = ConcatIndices(indexArrayArray, lenTotal, 0);
    BufferRemoveIndices(buffer, indices);
}

void BufferRemoveAllExceptFirst(
    TM::InputEventBuffer@ const buffer,
    const ms start, const ms end,
    const InputType type)
{
    if (start > end)
        return;

    uint lenTotal;
    const auto@ const indexArrayArray = BufferGetAllIndices(buffer, start, end, type, lenTotal);
    lenTotal -= (end - start) / TICK + 1;

    const auto@ const indices = ConcatIndices(indexArrayArray, lenTotal, 1);
    BufferRemoveIndices(buffer, indices);
}

void BufferRemoveIndices(TM::InputEventBuffer@ const buffer, const array<uint>@ const indices)
{
    if (indices.IsEmpty()) return;

    uint contiguous = 1;
    uint old = indices[indices.Length - 1];
    for (int i = indices.Length - 2; i != -1; i--)
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

array<uint>@ ConcatIndices(const array<array<uint>@>@ const indexArrayArray, const int capacity, const uint innerIndex)
{
    array<uint> indices(capacity);
    uint index = 0;
    for (uint i = 0; i < indexArrayArray.Length; i++)
    {
        const auto@ const indexArray = indexArrayArray[i];
        for (uint j = innerIndex; j < indexArray.Length; j++)
        {
            indices[index++] = indexArray[j];
        }
    }
    return indices;
}

// range
abstract class Range
{
    Range() {}

    Range(const int start, const int stop, const int step)
    {
        this.start = start;
        this.stop = stop;
        this.step = step;
    }

    protected int start;
    protected int stop;
    protected int step;

    bool Done { get const { return true; } }

    int Iter()
    {
        if (Done) return 0;

        const int temp = start;
        start += step;
        return ClampSteer(temp);
    }
}

class RangeIncl : Range
{
    RangeIncl() { super(); }

    RangeIncl(const int start, const int stop, const int step)
    {
        super(start, stop, step);
    }

    bool Done { get const override { return start > stop || step == 0; } }
}

class RangeExcl : Range
{
    RangeExcl() { super(); }

    RangeExcl(const int start, const int stop, const int step)
    {
        super(start, stop, step);
    }

    bool Done { get const override { return start >= stop || step == 0; } }
}

// log
void log() { log(""); }
void log(const bool b, Severity severity = Severity::Info) { log("" + b, severity); }
void log(const uint u, Severity severity = Severity::Info) { log("" + u, severity); }
void log(const int i, Severity severity = Severity::Info) { log("" + i, severity); }
void log(const float f, Severity severity = Severity::Info) { log("" + f, severity); }
void log(const double d, Severity severity = Severity::Info) { log("" + d, severity); }

// print
void print() { print(""); }
void print(const bool b, Severity severity = Severity::Info) { print("" + b, severity); }
void print(const uint u, Severity severity = Severity::Info) { print("" + u, severity); }
void print(const int i, Severity severity = Severity::Info) { print("" + i, severity); }
void print(const float f, Severity severity = Severity::Info) { print("" + f, severity); }
void print(const double d, Severity severity = Severity::Info) { print("" + d, severity); }
