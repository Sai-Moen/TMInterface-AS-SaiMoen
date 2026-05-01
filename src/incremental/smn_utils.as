/*

v3.0.0
smn_utils, useful code snippets, by SaiMoen.

To find contents, search for "# [name]", where [name] is one of the items below.

Contents:
- API overrides/extensions/etc.
  - Global
  - Text
  - Time
  - TM
  - UI
- Miscellaneous
  - Assert
  - Steer
  - String

*/




// # API overrides/extensions/etc.



/*

# Global

Features:
- Var Get/Set Wrappers.
- Log overloads.
- Print overloads.
- Misc.
- TM-adjacent.

*/


bool    VarGetBool(  const string &in name) { return                 GetVariableBool(  name ); }
uint    VarGetUint(  const string &in name) { return uint(           GetVariableDouble(name)); }
uint64  VarGetUint64(const string &in name) { return uint64(         GetVariableDouble(name)); }
int     VarGetInt(   const string &in name) { return int(            GetVariableDouble(name)); }
int64   VarGetInt64( const string &in name) { return int64(          GetVariableDouble(name)); }
ms      VarGetMs(    const string &in name) { return ms(             GetVariableDouble(name)); }
float   VarGetFloat( const string &in name) { return float(          GetVariableDouble(name)); }
double  VarGetDouble(const string &in name) { return                 GetVariableDouble(name ); }
vec2    VarGetVec2(  const string &in name) { return Text::ParseVec2(GetVariableString(name)); }
vec3    VarGetVec3(  const string &in name) { return Text::ParseVec3(GetVariableString(name)); }
String@ VarGetString(const string &in name) { return                 GetVariableString(name ); }

bool VarSetBool(  const string &in name, const bool       value) { return SetVariable(name,        value);            }
bool VarSetUint(  const string &in name, const uint       value) { return SetVariable(name, double(value));           }
bool VarSetUint64(const string &in name, const uint64     value) { return SetVariable(name, double(value));           }
bool VarSetInt(   const string &in name, const int        value) { return SetVariable(name, double(value));           }
bool VarSetInt64( const string &in name, const int64      value) { return SetVariable(name, double(value));           }
bool VarSetMs(    const string &in name, const ms         value) { return SetVariable(name, double(value));           }
bool VarSetFloat( const string &in name, const float      value) { return SetVariable(name, double(value));           }
bool VarSetDouble(const string &in name, const double     value) { return SetVariable(name,        value);            }
bool VarSetVec2(  const string &in name, const vec2       value) { return SetVariable(name,        value.ToString()); }
bool VarSetVec3(  const string &in name, const vec3       value) { return SetVariable(name,        value.ToString()); }
bool VarSetString(const string &in name, const string &in value) { return SetVariable(name,        value);            }


void log() { log(""); }

void log(const bool value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint value,   Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint64 value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int value,    Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int64 value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const float value,  Severity severity = Severity::Info) { log("" + value, severity); }
void log(const double value, Severity severity = Severity::Info) { log("" + value, severity); }

void log(const vec2 value, Severity severity = Severity::Info) { log(value.ToString(), severity); }
void log(const vec3 value, Severity severity = Severity::Info) { log(value.ToString(), severity); }


void print() { print(""); }

void print(const bool value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint value,   Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint64 value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int value,    Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int64 value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const float value,  Severity severity = Severity::Info) { print("" + value, severity); }
void print(const double value, Severity severity = Severity::Info) { print("" + value, severity); }

void print(const vec2 value, Severity severity = Severity::Info) { print(value.ToString(), severity); }
void print(const vec3 value, Severity severity = Severity::Info) { print(value.ToString(), severity); }


void DrawGame(const bool value)
{
    SetVariable("draw_game", value);
}


// Run-mode only: SetInputState, but asserts that it does not add an input event.
void ModifyInputState(SimulationManager@ sim, InputType state, int value)
{
    const auto@ const buffer = sim.InputEvents;
    const uint lengthOld = buffer.Length;
    sim.SetInputState(state, value);
    const uint lengthNew = buffer.Length;
    Assert(lengthOld == lengthNew);
}

// Run-mode only: ModifyInputState for each event in the IEB at RaceTime.
void ApplyInputStates(SimulationManager@ sim)
{
    // Assuming main overload checks for oob and wrong time anyway, thus using Search, not Find.
    ApplyInputStates(sim, BufferSearchTime(sim.InputEvents, sim.RaceTime, -1));
}

// Run-mode only: ModifyInputState for each event in the IEB at RaceTime, with a given starting index.
void ApplyInputStates(SimulationManager@ sim, const uint index)
{
    auto@ const buffer = sim.InputEvents;
    const uint bufferLen = buffer.Length;
    if (index >= bufferLen)
        return;

    const ums timestamp = sim.RaceTime + IEB_TIME_OFFSET;
    if (buffer[index].Time != timestamp)
        return;

    const array<InputType>@ mapping = EventIndicesMakeMapping(buffer.EventIndices);
    for (uint i = index; i < bufferLen; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Time != timestamp)
            break;

        TM::InputEventValue inputEventValue = inputEvent.Value;
        const int8 eventIndex = inputEventValue.EventIndex;
        const InputType state = EventIndicesMappingGet(mapping, eventIndex);
        if (state == InputType::None)
        {
            log("Unknown Input Type, EventIndex: " + eventIndex, Severity::Warning);
            continue;
        }

        ModifyInputState(sim, state, InputEventValueToInt(inputEventValue, state));
    }
}

// Rewind, with default behavior, as well as applying inputs in run mode.
void RewindDefault(SimulationManager@ sim, SimulationState@ state, const bool resetCamera = true)
{
	sim.RewindToState(state, resetCamera);

	switch (state.Mode)
	{
	case ContextMode::Simulation:
	break;
	case ContextMode::Run:
		ApplyInputStates(sim);
	break;
	default:
		Unreachable();
	break;
	}
}

// Rewind, but preserve IEB.
void RewindPreserve(SimulationManager@ sim, SimulationState@ state, const bool resetCamera = true)
{
    array<TM::InputEvent> preserved;

    switch (state.Mode)
    {
    case ContextMode::Simulation:
        // In sim mode, inputs are not modified.
    break;
    case ContextMode::Run:
        {
            const auto@ const buffer = sim.InputEvents;
            const uint index = BufferSearchTime(buffer, state.PlayerInfo.RaceTime, -1);
            const uint length = buffer.Length - index;
            if (length == 0)
                break;

            preserved.Resize(length);
            for (uint i = 0; i < length; ++i)
                preserved[i] = buffer[index + i];
        }
    break;
    default:
        Unreachable();
    break;
    }

    sim.RewindToState(state, resetCamera);

    switch (state.Mode)
    {
    case ContextMode::Simulation:
        // In sim mode, inputs are not modified.
    break;
    case ContextMode::Run:
        {
            const uint length = preserved.Length;
            if (length == 0)
                break;

            auto@ const buffer = sim.InputEvents;
            const uint index = buffer.Length;

            for (uint i = 0; i < length; ++i)
                buffer.Add(preserved[i]);

            ApplyInputStates(sim, index);
        }
    break;
    default:
        Unreachable();
    break;
    }
}

// Rewind, but remove input events starting from state.PlayerInfo.RaceTime.
void RewindRemove(SimulationManager@ sim, SimulationState@ state, const bool resetCamera = true)
{
    sim.RewindToState(state, resetCamera);

    switch (state.Mode)
    {
    case ContextMode::Simulation:
        {
            auto@ const buffer = sim.InputEvents;
            const uint index = BufferSearchTime(buffer, state.PlayerInfo.RaceTime, -1);
            BufferKeepUntil(buffer, index);
        }
    break;
    case ContextMode::Run:
        ApplyInputStates(sim);
    break;
    default:
        Unreachable();
    break;
    }
}



/*

# Text

Features:
- Parse wrappers.
- PreciseFormat.

*/


bool ParseUInt(const string &in s, uint64 &out value, const uint base = 10)
{
    uint byteCount;
    value = Text::ParseUInt(s, base, byteCount);
    return byteCount != 0;
}

bool ParseInt(const string &in s, int64 &out value, const uint base = 10)
{
    uint byteCount;
    value = Text::ParseInt(s, base, byteCount);
    return byteCount != 0;
}

bool ParseFloat(const string &in s, double &out value)
{
    uint byteCount;
    value = Text::ParseFloat(s, byteCount);
    return byteCount != 0;
}


String@ FormatPrecise(const double value, const uint precision = 12)
{
    return Text::FormatFloat(value, " ", 0, precision);
}

String@ FormatPrecise(const vec2 &in value, const uint precision = 12)
{
    const string x = FormatPrecise(value.x, precision);
    const string y = FormatPrecise(value.y, precision);

    string s;
    s.Resize(x.Length + 1 + y.Length);

    uint i = 0;
    for (uint j = 0; j < x.Length; j++)
        s[i++] = x[j];
    s[i++] = ' ';
    for (uint j = 0; j < y.Length; j++)
        s[i++] = y[j];

    return s;
}

String@ FormatPrecise(const vec3 &in value, const uint precision = 12)
{
    const string x = FormatPrecise(value.x, precision);
    const string y = FormatPrecise(value.y, precision);
    const string z = FormatPrecise(value.z, precision);

    string s;
    s.Resize(x.Length + 1 + y.Length + 1 + z.Length);

    uint i = 0;
    for (uint j = 0; j < x.Length; j++)
        s[i++] = x[j];
    s[i++] = ' ';
    for (uint j = 0; j < y.Length; j++)
        s[i++] = y[j];
    s[i++] = ' ';
    for (uint j = 0; j < z.Length; j++)
        s[i++] = z[j];

    return s;
}



/*

# Time

Features:
- Milliseconds aliases.
- Parse wrapper.

*/


typedef uint32 ums; // Input Event Buffer timestamps.
typedef int32 ms; // TMInterface-adjusted time.

bool ParseTime(const string &in raceTime, int &out value)
{
    value = Time::Parse(raceTime);
    return value != -1;
}



/*

# TM

Features:
- TM::InputEventBuffer (IEB) helpers.
- EventIndices helpers.
- Input Event helpers.

Notes:
By convention, 'time' means TMInterface-adjusted time, and 'timestamp' is the InputEvent time, i.e.
ms time = timestamp - 100010,
ums timestamp = time + 100010.

*/


const ums IEB_TIME_OFFSET = 100010;

// Binary search for time.
// Returns index (<= buffer.Length) of where an input event would have been added (given the time and direction).
uint BufferSearchTime(const TM::InputEventBuffer@ buffer, const ms time, const int direction)
{
    return BufferSearchTimestamp(buffer, time + IEB_TIME_OFFSET, direction);
}

// Binary search for timestamp, then go left or right depending on direction (or just return), to find one end of a time region.
// Returns index (<= buffer.Length) of where an input event would have been added (given the timestamp and direction).
uint BufferSearchTimestamp(const TM::InputEventBuffer@ buffer, const ums timestamp, const int direction)
{
    const uint length = buffer.Length;
    if (length == 0)
        return 0;

    uint index = 0;
    for (uint lower = 0, upper = length;;)
    {
        const uint diff = upper - lower;
        if (diff < 2)
        {
            index = lower;
            break;
        }

        const uint mid = lower + diff / 2;
        const ums midTimestamp = buffer[mid].Time;
        if (midTimestamp == timestamp)
        {
            index = mid;
            break;
        }

        // lol
        (midTimestamp < timestamp ? lower : upper) = mid;
    }

    const ums indexTimestamp = buffer[index].Time;
    if (indexTimestamp == timestamp)
    {
        if (direction != 0)
        {
            for (;;)
            {
                const uint next = index + direction;
                if (next >= length || buffer[next].Time != timestamp)
                    break;

                index = next;
            }
        }
    }
    else if (indexTimestamp < timestamp)
    {
        ++index;
    }

    return index;
}

// Binary search for time.
// Returns -1 if not found.
int BufferFindTime(const TM::InputEventBuffer@ buffer, const ms time, const int direction)
{
    return BufferFindTimestamp(buffer, time + IEB_TIME_OFFSET, direction);
}

// Binary search for timestamp, then go left or right depending on direction (or just return), to find one end of a time region.
// Returns -1 if not found.
int BufferFindTimestamp(const TM::InputEventBuffer@ buffer, const ums timestamp, const int direction)
{
    const uint index = BufferSearchTimestamp(buffer, timestamp, direction);
    if (index >= buffer.Length || buffer[index].Time != timestamp)
        return -1;

    return index;
}

// Returns: non-null handle to an array of indices of input events in the timerange of a type from inputTypes.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const array<InputType>@ inputTypes)
{
    if (timeTo < timeFrom)
        return {};

    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    return BufferFindInTimerange(buffer, timeFrom, timeTo, mask);
}

// Returns: non-null handle to an array of indices of input events in the timerange matching the mask.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const uint mask)
{
    if (timeTo < timeFrom)
        return {};

    const ums timestampFrom = timeFrom + IEB_TIME_OFFSET;
    const ums timestampTo   = timeTo   + IEB_TIME_OFFSET;

    const uint length = buffer.Length;
    array<uint> indices((timeTo - timeFrom + 1) * 10);
    const uint index = BufferSearchTimestamp(buffer, timestampFrom, -1);
    for (uint i = index; i < length; ++i)
    {
        const auto inputEvent = buffer[i];
        if (inputEvent.Time > timestampTo)
            break;

        const uint masked = (1 << inputEvent.Value.EventIndex) & mask;
        if (masked != 0)
            indices.Add(i);
    }
    return indices;
}

// Effectively sets 'buffer.Length' to 'index'.
// If index > buffer.Length, it will throw an exception (it will not try to add dummy input events).
void BufferKeepUntil(TM::InputEventBuffer@ buffer, const uint index)
{
    const uint length = buffer.Length;
    // NOTE: this if-statement is only needed due to an edge case in TMInterface.
    // != is chosen so we do not hide correctness issues in the caller's code.
    if (length != index)
        buffer.RemoveAt(index, length - index);
}

void BufferRemoveInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const array<InputType>@ inputTypes)
{
    if (timeTo < timeFrom)
        return;

    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    const array<uint>@ indices = BufferFindInTimerange(buffer, timeFrom, timeTo, mask);
    BufferRemoveIndices(buffer, indices);
}

void BufferRemoveInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const uint mask)
{
    if (timeTo < timeFrom)
        return;

    const array<uint>@ indices = BufferFindInTimerange(buffer, timeFrom, timeTo, mask);
    BufferRemoveIndices(buffer, indices);
}

// NOTE: indices must be sorted in ascending order (getting indices from a linear search like Find, does this automatically).
void BufferRemoveIndices(TM::InputEventBuffer@ buffer, const array<uint>@ indices, const uint indicesBase = 0)
{
    const uint indicesLen = indices.Length;
    if (indicesBase >= indicesLen)
        return;

    uint indicesIndex = indicesBase;
    uint index = indices[indicesIndex++];
    const uint bufferLen = buffer.Length;
    for (uint i = index + 1; i < bufferLen; ++i)
    {
        if (indicesIndex < indicesLen && i == indices[indicesIndex])
            ++indicesIndex;
        else
            buffer[index++] = buffer[i];
    }
    BufferKeepUntil(buffer, index);
}

// Turn an array<InputType> into a bitmask where the 1's are shifted event indices of which the InputType was in the array.
// We assume here that uint suffices, based on the largest InputType member being smaller than the amount of bits in a uint.
// Otherwise, make a bit array version.
uint EventIndicesMakeInputTypesBitmask(const EventIndices &in eventIndices, const array<InputType>@ inputTypes)
{
    uint mask = 0;

    const uint length = inputTypes.Length;
    for (uint i = 0; i < length; ++i)
    {
        int eventIndex = -1;

        switch (inputTypes[i])
        {
        case InputType::Down:       eventIndex = eventIndices.BrakeId;      break;
        case InputType::Up:         eventIndex = eventIndices.AccelerateId; break;
        case InputType::Left:       eventIndex = eventIndices.SteerLeftId;  break;
        case InputType::Right:      eventIndex = eventIndices.SteerRightId; break;
        case InputType::Steer:      eventIndex = eventIndices.SteerId;      break;
        case InputType::Gas:        eventIndex = eventIndices.GasId;        break;
        case InputType::Respawn:    eventIndex = eventIndices.RespawnId;    break;
        //   InputType::GiveUp: I assume this one does not show up in the IEB...
        case InputType::Horn:       eventIndex = eventIndices.HornId;       break;
        case InputType::FakeFinish: eventIndex = eventIndices.FinishLineId; break;
        default:
            PanicLog("Undefined InputType in EventIndicesMakeInputTypesBitmask");
        break;
        }

        Assert(eventIndex < 32); // Amount of bits in a uint (a constant would pollute global scope).
        mask |= 1 << eventIndex;
    }

    return mask;
}

InputType EventIndicesDecode(const EventIndices &in eventIndices, const int8 eventIndex)
{
    InputType inputType = InputType::None;
    if (eventIndex == eventIndices.BrakeId)
        inputType = InputType::Down;
    else if (eventIndex == eventIndices.AccelerateId)
        inputType = InputType::Up;
    else if (eventIndex == eventIndices.SteerLeftId)
        inputType = InputType::Left;
    else if (eventIndex == eventIndices.SteerRightId)
        inputType = InputType::Right;
    else if (eventIndex == eventIndices.SteerId)
        inputType = InputType::Steer;
    else if (eventIndex == eventIndices.GasId)
        inputType = InputType::Gas;
    else if (eventIndex == eventIndices.RespawnId)
        inputType = InputType::Respawn;
    else if (eventIndex == eventIndices.HornId)
        inputType = InputType::Horn;
    else if (eventIndex == eventIndices.FinishLineId)
        inputType = InputType::FakeFinish;
    return inputType;
}

// NOTE: This mapping assumes there are no unknown event indices in the IEB.
array<InputType>@ EventIndicesMakeMapping(const EventIndices &in eventIndices)
{
    // To make it really safe, we list all the ids (sorted by corresponding InputType),
    // and we determine the necessary capacity dynamically.

    const array<int> ids =
    {
        eventIndices.BrakeId,
        eventIndices.AccelerateId,
        eventIndices.SteerLeftId,
        eventIndices.SteerRightId,
        eventIndices.SteerId,
        eventIndices.GasId,
        eventIndices.RespawnId,
        -1, // GiveUp does not have a corresponding Id.
        eventIndices.HornId,
        eventIndices.FinishLineId
    };
    const uint idsLen = ids.Length;

    int capacity = 0;
    for (uint i = 0; i < idsLen; ++i)
    {
        const int requiredCapacity = ids[i] + 1;
        if (capacity < requiredCapacity)
            capacity = requiredCapacity;
    }

    array<InputType> mapping(capacity);
    for (int i = 0; i < capacity; ++i)
        mapping[i] = InputType::None;

    for (uint i = 0; i < idsLen; ++i)
    {
        const int id = ids[i];
        if (id != -1)
            mapping[id] = InputType(i);
    }
    return mapping;
}

InputType EventIndicesMappingGet(const array<InputType>@ mapping, const int8 eventIndex)
{
    return eventIndex < int(mapping.Length) ? mapping[eventIndex] : InputType::None;
}

int InputEventValueToInt(TM::InputEventValue &in inputEventValue, InputType state)
{
    int value;
    switch (state)
    {
    case InputType::Down:
    case InputType::Up:
    case InputType::Left:
    case InputType::Right:
        value = inputEventValue.Binary ? 1 : 0;
    break;
    default:
        value = inputEventValue.Analog;
    break;
    }
    return value;
}



/*

# UI

Features:
- Widget helpers.

*/


void TooltipOnHover(const string &in text)
{
    if (UI::IsItemHovered())
    {
        if (UI::BeginTooltip())
        {
            UI::Text(text);
            UI::EndTooltip();
        }
    }
}

// Combo with index.
funcdef void OnSelectIndex(const uint index);

bool ComboHelper(const string &in label, const array<string>@ names, const uint currentIndex, OnSelectIndex@ onSelect)
{
    const bool isOpen = UI::BeginCombo(label, names[currentIndex]);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = names[i];
            if (UI::Selectable(name, i == currentIndex))
                onSelect(i);
        }

        UI::EndCombo();
    }
    return isOpen;
}

// Combo with string.
funcdef void OnSelectName(const string &in name);

bool ComboHelper(const string &in label, const array<string>@ names, const string &in currentName, OnSelectName@ onSelect)
{
    const bool isOpen = UI::BeginCombo(label, currentName);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = names[i];
            if (UI::Selectable(name, name == currentName))
                onSelect(name);
        }

        UI::EndCombo();
    }
    return isOpen;
}




// # Miscellaneous



/*

# Assert

Features:
- Unreachable.
- Panic.
- Assert.

*/


funcdef void OnUnreachable();

void Unreachable()
{
	OnUnreachable@ unreachable;
	// This function only gets called if something went wrong.
	unreachable();
}

funcdef void OnPanic(const string &in message);

void IgnoreError(const string &in message) {}

void LogError(const string &in message)
{
	log(message, Severity::Error);
}

void PrintError(const string &in message)
{
	print(message, Severity::Error);
}

void Panic(const string &in message, const OnPanic@ callback)
{
	callback(message);
	Unreachable();
}

void Panic()
{
	Panic("", IgnoreError);
}

void PanicLog(const string &in message)
{
	Panic(message, LogError);
}

void PanicPrint(const string &in message)
{
	Panic(message, PrintError);
}

void Assert(const bool condition, const string &in message, const OnPanic@ callback)
{
	if (condition)
		return;

	Panic(message, callback);
}

void Assert(const bool condition)
{
	Assert(condition, "", IgnoreError);
}

void AssertLog(const bool condition, const string &in message)
{
	Assert(condition, message, LogError);
}

void AssertPrint(const bool condition, const string &in message)
{
	Assert(condition, message, PrintError);
}



/*

# Steer

Features:
- Constants.
- Conversion, Clamping.
- Sign, Rounding.

*/


const int STEER_FULL = 0x10000;
const int STEER_MIN  = -STEER_FULL;
const int STEER_MAX  =  STEER_FULL;

const int STEER_HALF = STEER_FULL / 2;

int ToSteer(const float small)
{
    return int(small * STEER_FULL);
}

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER_MIN, STEER_MAX);
}

enum Sign
{
    Negative = -1,
    Zero = 0,
    Positive = 1,
}

Sign GetSign(const int num)
{
    return Sign((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

Sign GetSign(const float num)
{
    return Sign((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

int RoundAway(const float magnitude, const float direction)
{
    return RoundAway(magnitude, GetSign(direction));
}

int RoundAway(const float magnitude, const Sign direction)
{
    switch (direction)
    {
    case Sign::Negative: return int(Math::Floor(magnitude));
    case Sign::Zero:     return int(magnitude);
    case Sign::Positive: return int(Math::Ceil(magnitude));
    default:             return 0; // unreachable
    }
}



/*

# String

Features:
- String reference class.
- String array helpers.
- String helpers.
- Character helpers.

*/


// A reference type containing a 'string', which can be passed around by handle,
// in cases where return references do not suffice.
// There is an implicit conversion from string to String (constructor not marked with 'explicit'),
// and there is an implicit conversion from String to string (opImplConv with a return reference).
class String
{
    string str;

    String() {}

    String(const string &in s)
    {
        str = s;
    }

    string& opImplConv()
    {
        return str;
    }
}

uint StringArrayCombinedLength(const array<string>@ strings)
{
    uint combined = 0;
    const uint len = strings.Length;
    for (uint i = 0; i < len; ++i)
        combined += strings[i].Length;
    return combined;
}

// To copy: string copy = StringPadLeft(string(s), lengthNew, c);
String@ StringPadLeft(string& s, const uint lengthNew, const uint8 c = ' ')
{
    const uint lengthOld = s.Length;
    if (lengthNew <= lengthOld)
        return s;

    s.Resize(lengthNew);

    const uint padBy = lengthNew - lengthOld;
    for (uint i = lengthNew - 1; i >= padBy; --i)
        s[i] = s[i - padBy];

    for (uint i = 0; i < padBy; ++i)
        s[i] = c;

    return s;
}

String@ StringPadLeftBy(string& s, const uint padBy, const uint8 c = ' ')
{
    return StringPadLeft(s, s.Length + padBy, c);
}

// To copy: string copy = StringPadRight(string(s), lengthNew, c);
String@ StringPadRight(string& s, const uint lengthNew, const uint8 c = ' ')
{
    const uint lengthOld = s.Length;
    if (lengthNew <= lengthOld)
        return s;

    s.Resize(lengthNew);

    for (uint i = lengthOld; i < lengthNew; ++i)
        s[i] = c;

    return s;
}

String@ StringPadRightBy(string& s, const uint padBy, const uint8 c = ' ')
{
    return StringPadRight(s, s.Length + padBy, c);
}

// Could also do Join, but that is built-in already.

String@ StringConcat(const array<string>@ strings, const uint extraLength = 0)
{
    string s;
    s.Resize(extraLength + StringArrayCombinedLength(strings));

    uint index = 0;
    const uint len = strings.Length;
    for (uint i = 0; i < len; ++i)
    {
        for (uint j = 0; j < strings[i].Length; ++j)
            s[index++] = strings[i][j];
    }

    return s;
}

String@ StringConcatWithPrefix(const array<string>@ strings, const string &in prefix, const uint extraLength = 0)
{
    string s;

    const uint len = strings.Length;
    s.Resize(extraLength + len + StringArrayCombinedLength(strings));

    uint index = 0;
    for (uint i = 0; i < len; ++i)
    {
        for (uint j = 0; j < prefix.Length; ++j)
            s[index++] = prefix[j];

        for (uint j = 0; j < strings[i].Length; ++j)
            s[index++] = strings[i][j];
    }

    return s;
}

String@ StringConcatWithPostfix(const array<string>@ strings, const string &in postfix, const uint extraLength = 0)
{
    string s;

    const uint len = strings.Length;
    s.Resize(extraLength + len + StringArrayCombinedLength(strings));

    uint index = 0;
    for (uint i = 0; i < len; ++i)
    {
        for (uint j = 0; j < strings[i].Length; ++j)
            s[index++] = strings[i][j];

        for (uint j = 0; j < postfix.Length; ++j)
            s[index++] = postfix[j];
    }

    return s;
}

uint StringGetLastLineLength(const string &in s)
{
    int right = s.Length - 1;
    while (right != -1)
    {
        if (s[right--] == '\n')
            break;
    }

    int left = right;
    while (left != -1)
    {
        if (s[left] == '\n')
            break;

        --left;
    }

    return right - left;
}

String@ CharRepeat(const uint times, const uint8 c = ' ')
{
    string s;
    s.Resize(times);
    for (uint i = 0; i < times; ++i)
        s[i] = c;
    return s;
}
