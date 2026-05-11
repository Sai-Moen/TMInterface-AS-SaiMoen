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

void log(const bool   value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint8  value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint16 value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint32 value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const uint64 value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int8   value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int16  value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int32  value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const int64  value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const float  value, Severity severity = Severity::Info) { log("" + value, severity); }
void log(const double value, Severity severity = Severity::Info) { log("" + value, severity); }

void log(const vec2 value, Severity severity = Severity::Info) { log(value.ToString(), severity); }
void log(const vec3 value, Severity severity = Severity::Info) { log(value.ToString(), severity); }
void log(const vec4 value, Severity severity = Severity::Info) { log(value.ToString(), severity); }
void log(const quat value, Severity severity = Severity::Info) { log(value.ToString(), severity); }


void print() { print(""); }

void print(const bool   value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint8  value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint16 value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint32 value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const uint64 value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int8   value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int16  value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int32  value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const int64  value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const float  value, Severity severity = Severity::Info) { print("" + value, severity); }
void print(const double value, Severity severity = Severity::Info) { print("" + value, severity); }

void print(const vec2 value, Severity severity = Severity::Info) { print(value.ToString(), severity); }
void print(const vec3 value, Severity severity = Severity::Info) { print(value.ToString(), severity); }
void print(const vec4 value, Severity severity = Severity::Info) { print(value.ToString(), severity); }
void print(const quat value, Severity severity = Severity::Info) { print(value.ToString(), severity); }


void DrawGame(const bool value)
{
    SetVariable("draw_game", value);
}


// Keep in sync (as if it will ever change).
const uint INPUT_TYPE_COUNT = 10;

// ContextMode::Run only (ContextMode::Simulation always adds): SetInputState, but asserts that it does not add an input event.
void ModifyInputState(SimulationManager@ sim, InputType state, int value)
{
    const auto@ const buffer = sim.InputEvents;
    const uint lengthOld = buffer.Length;
    sim.SetInputState(state, value);
    const uint lengthNew = buffer.Length;
    Assert(lengthOld == lengthNew);
}

// ContextMode::Run only: ModifyInputState for each event in the IEB at TickTime.
void ApplyInputEvents(SimulationManager@ sim)
{
    // Assuming main overload checks for oob and wrong time anyway, thus using Search, not Find.
    ApplyInputEvents(sim, BufferSearchTime(sim.InputEvents, sim.TickTime, -1));
}

// ContextMode::Run only: ModifyInputState for each event in the IEB at TickTime, with a given starting index.
void ApplyInputEvents(SimulationManager@ sim, const uint index)
{
    const auto@ const buffer = sim.InputEvents;
    const uint bufferLen = buffer.Length;
    if (index >= bufferLen)
        return;

    const ums timestamp = IEB_TIME_OFFSET + sim.TickTime;
    if (buffer[index].Time != timestamp)
        return;

    const array<InputType>@ mapping = EventIndicesMakeMapping(buffer.EventIndices);
    for (uint i = index; i < bufferLen; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Time != timestamp)
            break;

        TM::InputEventValue inputEventValue = inputEvent.Value;
        const int eventIndex = inputEventValue.EventIndex;
        const InputType state = EventIndicesMappingDecode(mapping, eventIndex);
        if (state == InputType::None)
        {
            log("Unknown Input Type, EventIndex: " + eventIndex, Severity::Warning);
            continue;
        }

        ModifyInputState(sim, state, InputEventValueGetInt(inputEventValue, state));
    }
}

// Rewind, with default behavior, as well as applying inputs in run mode.
void RewindDefault(SimulationManager@ sim, SimulationState@ state, const bool resetCamera = true)
{
	sim.RewindToState(state, resetCamera);

	switch (state.Mode)
	{
	case ContextMode::Simulation:
        // In sim mode, input events are always applied.
	break;
	case ContextMode::Run:
		ApplyInputEvents(sim);
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

            ApplyInputEvents(sim, index);
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
            BufferRemoveFromIndex(buffer, index);
        }
    break;
    case ContextMode::Run:
        ApplyInputEvents(sim);
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
// Returns index (<= buffer.Length) of where an input event would have been added (given the time and direction).
uint BufferSearchTime(const TM::InputEventBuffer@ buffer, const ms time, const int direction)
{
    return BufferSearchTimestamp(buffer, IEB_TIME_OFFSET + time, direction);
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

// Binary search for time.
// Returns -1 if not found.
int BufferFindTime(const TM::InputEventBuffer@ buffer, const ms time, const int direction)
{
    return BufferFindTimestamp(buffer, IEB_TIME_OFFSET + time, direction);
}

// Returns the first index of an input event with the given timestamp and event index.
// If no such event exists, returns 0, thus if you are looking for RaceRunningId, check buffer[0] first.
uint BufferFindFirst(const TM::InputEventBuffer@ buffer, const ums timestamp, const int eventIndex)
{
    uint index = 0;

    const uint bufferIndex = BufferSearchTimestamp(buffer, timestamp, -1);
    const uint bufferLen = buffer.Length;
    for (uint i = bufferIndex; i < bufferLen; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Time > timestamp)
            break;

        if (inputEvent.Value.EventIndex == eventIndex)
        {
            index = i;
            break;
        }
    }

    return index;
}

// Returns: non-null handle to an array of indices of input events in the timerange matching the mask.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ums timestampFrom, const ums timestampTo, const uint mask)
{
    if (timestampFrom > timestampTo)
        return {};

    array<uint> indices;
    const uint index = BufferSearchTimestamp(buffer, timestampFrom, -1);
    const uint length = buffer.Length;
    for (uint i = index; i < length; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Time > timestampTo)
            break;

        if (InputEventIsMasked(inputEvent, mask))
            indices.Add(i);
    }
    return indices;
}

// Returns: non-null handle to an array of indices of input events in the timerange of a type from inputTypes.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ums timestampFrom, const ums timestampTo, const array<InputType>@ inputTypes)
{
    if (timestampFrom > timestampTo)
        return {};

    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    return BufferFindInTimerange(buffer, timestampFrom, timestampTo, mask);
}

// Returns: non-null handle to an array of indices of input events in the timerange matching the mask.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const uint mask)
{
    if (timeFrom > timeTo)
        return {};

    const ums timestampFrom = IEB_TIME_OFFSET + timeFrom;
    const ums timestampTo   = IEB_TIME_OFFSET + timeTo;
    return BufferFindInTimerange(buffer, timestampFrom, timestampTo, mask);
}

// Returns: non-null handle to an array of indices of input events in the timerange of a type from inputTypes.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const array<InputType>@ inputTypes)
{
    if (timeFrom > timeTo)
        return {};

    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    return BufferFindInTimerange(buffer, timeFrom, timeTo, mask);
}

// Removes the range of input events from 'lower' to 'upper' (exclusive).
// If lower > upper, it will throw an exception (it will not try to add dummy input events).
void BufferRemoveRange(TM::InputEventBuffer@ buffer, const uint lower, const uint upper)
{
    // NOTE: this if-statement is only needed due to an edge case in TMInterface (as of writing).
    // != is chosen so we do not hide correctness issues in the caller's code.
    if (upper != lower)
        buffer.RemoveAt(lower, upper - lower);
}

// Attempts to lower 'buffer.Length' to 'index'.
// If index > buffer.Length, it will throw an exception (it will not try to add dummy input events).
void BufferRemoveFromIndex(TM::InputEventBuffer@ buffer, const uint index)
{
    BufferRemoveRange(buffer, index, buffer.Length);
}

void BufferRemoveEventIndex(TM::InputEventBuffer@ buffer, const int eventIndex)
{
    uint index = 0;
    const uint length = buffer.Length;

    while (index < length)
    {
        const TM::InputEvent inputEvent = buffer[index++];
        if (inputEvent.Value.EventIndex == eventIndex)
            break;
    }

    for (uint i = index; i < length; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Value.EventIndex != eventIndex)
            buffer[index++] = inputEvent;
    }

    BufferRemoveFromIndex(buffer, index);
}

void BufferRemoveInputType(TM::InputEventBuffer@ buffer, const InputType inputType)
{
    const int eventIndex = EventIndicesEncode(buffer.EventIndices, inputType);
    BufferRemoveEventIndex(buffer, eventIndex);
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
    BufferRemoveFromIndex(buffer, index);
}

// Removes input events with the given timestamp and event index, after 'index'.
// The input event at 'index' is expected (and asserted) to be the first input event in the buffer with those properties.
void BufferRemoveDuplicatesAtTimestamp(
    TM::InputEventBuffer@ buffer, const ums timestamp, const int eventIndex, const uint index)
{
    Assert(buffer[index].Time == timestamp && buffer[index].Value.EventIndex == eventIndex);

    uint lower = 0;
    uint upper = index + 1;

    const uint bufferLen = buffer.Length;
    for (; upper < bufferLen; ++upper)
    {
        const TM::InputEvent inputEvent = buffer[upper];
        if (inputEvent.Time > timestamp)
            break;

        if (inputEvent.Value.EventIndex != eventIndex)
        {
            if (lower != 0)
                buffer[lower++] = inputEvent;

            continue;
        }

        if (lower == 0)
            lower = upper;
    }

    if (lower != 0)
        BufferRemoveRange(buffer, lower, upper);
}

void BufferRemoveFromTimestamp(TM::InputEventBuffer@ buffer, const ums timestamp, const uint mask)
{
    uint index = BufferSearchTimestamp(buffer, timestamp, -1);
    uint i;
    const uint length = buffer.Length;
    for (i = index; i < length; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (!InputEventIsMasked(inputEvent, mask))
            buffer[index++] = inputEvent;
    }
    BufferRemoveRange(buffer, index, i);
}

void BufferRemoveFromTimestamp(TM::InputEventBuffer@ buffer, const ums timestamp, const array<InputType>@ inputTypes)
{
    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    BufferRemoveFromTimestamp(buffer, timestamp, mask);
}

void BufferRemoveFromTime(TM::InputEventBuffer@ buffer, const ms time, const uint mask)
{
    BufferRemoveFromTimestamp(buffer, IEB_TIME_OFFSET + time, mask);
}

void BufferRemoveFromTime(TM::InputEventBuffer@ buffer, const ms time, const array<InputType>@ inputTypes)
{
    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    BufferRemoveFromTime(buffer, time, mask);
}

void BufferRemoveInTimestampRange(
    TM::InputEventBuffer@ buffer, const ums timestampFrom, const ums timestampTo, const uint mask)
{
    if (timestampFrom > timestampTo)
        return;

    uint index = BufferSearchTimestamp(buffer, timestampFrom, -1);
    uint i;
    const uint length = buffer.Length;
    for (i = index; i < length; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Time > timestampTo)
            break;

        if (!InputEventIsMasked(inputEvent, mask))
            buffer[index++] = inputEvent;
    }
    BufferRemoveRange(buffer, index, i);
}

void BufferRemoveInTimestampRange(
    TM::InputEventBuffer@ buffer, const ums timestampFrom, const ums timestampTo, const array<InputType>@ inputTypes)
{
    if (timestampFrom > timestampTo)
        return;

    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    BufferRemoveInTimestampRange(buffer, timestampFrom, timestampTo, mask);
}

void BufferRemoveInTimeRange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const uint mask)
{
    if (timeFrom > timeTo)
        return;

    const ums timestampFrom = IEB_TIME_OFFSET + timeFrom;
    const ums timestampTo   = IEB_TIME_OFFSET + timeTo;
    BufferRemoveInTimestampRange(buffer, timestampFrom, timestampTo, mask);
}

void BufferRemoveInTimeRange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const array<InputType>@ inputTypes)
{
    if (timeFrom > timeTo)
        return;

    const uint mask = EventIndicesMakeInputTypesBitmask(buffer.EventIndices, inputTypes);
    BufferRemoveInTimeRange(buffer, timeFrom, timeTo, mask);
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
        const int eventIndex = EventIndicesEncode(eventIndices, inputTypes[i]);
        Assert(eventIndex < 32); // Amount of bits in a uint (a constant would pollute global scope).
        mask |= 1 << eventIndex;
    }

    return mask;
}

int EventIndicesEncode(const EventIndices &in eventIndices, const InputType inputType)
{
    int eventIndex = -1;

    switch (inputType)
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
        PanicLog("Bad InputType in EventIndicesEncode");
    break;
    }

    return eventIndex;
}

InputType EventIndicesDecode(const EventIndices &in eventIndices, const int eventIndex)
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

    uint capacity = 0;
    for (uint i = 0; i < idsLen; ++i)
    {
        const uint requiredCapacity = ids[i] + 1;
        if (capacity < requiredCapacity)
            capacity = requiredCapacity;
    }

    array<InputType> mapping(capacity);
    for (uint i = 0; i < capacity; ++i)
        mapping[i] = InputType::None;

    for (uint i = 0; i < idsLen; ++i)
    {
        const int id = ids[i];
        if (id != -1)
            mapping[id] = InputType(i);
    }
    return mapping;
}

InputType EventIndicesMappingDecode(const array<InputType>@ mapping, const int eventIndex)
{
    const uint index = eventIndex;
    return index < mapping.Length ? mapping[index] : InputType::None;
}

bool InputEventIsMasked(const TM::InputEvent &in inputEvent, const uint mask)
{
    return ((1 << inputEvent.Value.EventIndex) & mask) != 0;
}

int InputEventGetInt(TM::InputEvent &in inputEvent, const InputType inputType)
{
    return InputEventValueGetInt(inputEvent.Value, inputType);
}

void InputEventSetInt(TM::InputEvent& inputEvent, const InputType inputType, const int value)
{
    InputEventValueSetInt(inputEvent.Value, inputType, value);
}

int InputEventValueGetInt(TM::InputEventValue inputEventValue, const InputType inputType)
{
    int value;
    switch (inputType)
    {
    case InputType::Down:
    case InputType::Up:
    case InputType::Left:
    case InputType::Right:
    case InputType::Respawn:
    case InputType::Horn:
    case InputType::FakeFinish:
        value = inputEventValue.Binary ? 1 : 0;
    break;
    case InputType::Steer:
    case InputType::Gas:
        value = inputEventValue.Analog;
    break;
    default:
        Unreachable();
    break;
    }
    return value;
}

void InputEventValueSetInt(TM::InputEventValue& inputEventValue, const InputType inputType, const int value)
{
    switch (inputType)
    {
    case InputType::Down:
    case InputType::Up:
    case InputType::Left:
    case InputType::Right:
    case InputType::Respawn:
    case InputType::Horn:
    case InputType::FakeFinish:
        inputEventValue.Binary = value != 0;
    break;
    case InputType::Steer:
    case InputType::Gas:
        inputEventValue.Analog = value;
    break;
    default:
        Unreachable();
    break;
    }
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

bool ComboSelectIndex(const string &in label, const array<string>@ names, const uint currentIndex, OnSelectIndex@ onSelect)
{
    const bool isOpen = UI::BeginCombo(label, names[currentIndex]);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            if (UI::Selectable(names[i], i == currentIndex))
                onSelect(i);
        }

        UI::EndCombo();
    }
    return isOpen;
}

// Combo with string.
funcdef void OnSelectName(const string &in name);

bool ComboSelectName(const string &in label, const array<string>@ names, const string &in currentName, OnSelectName@ onSelect)
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
	// This unbound function only gets called if something went wrong.
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
class String
{
    protected string str;

    String() const {}

    String(const string &in s) { str = s; }

    const string& opConv()     const { return str; }
          string& opConv()           { return str; }
    const string& opImplConv() const { return str; }
          string& opImplConv()       { return str; }
}

uint StringArrayCombinedLength(const array<string>@ strings)
{
    uint combined = 0;
    const uint len = strings.Length;
    for (uint i = 0; i < len; ++i)
        combined += strings[i].Length;
    return combined;
}

void StringPadLeft(string& s, const uint lengthNew, const uint8 c = ' ')
{
    const uint lengthOld = s.Length;
    if (lengthNew <= lengthOld)
        return;

    s.Resize(lengthNew);

    const uint padBy = lengthNew - lengthOld;
    for (uint i = lengthNew - 1; i >= padBy; --i)
        s[i] = s[i - padBy];

    for (uint i = 0; i < padBy; ++i)
        s[i] = c;
}

String@ StringCopyPadLeft(String@ copy, const uint lengthNew, const uint8 c = ' ')
{
    StringPadLeft(string(copy), lengthNew, c);
    return copy;
}

void StringPadLeftBy(string& s, const uint padBy, const uint8 c = ' ')
{
    StringPadLeft(s, s.Length + padBy, c);
}

String@ StringCopyPadLeftBy(String@ copy, const uint padBy, const uint8 c = ' ')
{
    StringPadLeftBy(string(copy), padBy, c);
    return copy;
}

// To copy: string copy = StringPadRight(string(s), lengthNew, c);
void StringPadRight(string& s, const uint lengthNew, const uint8 c = ' ')
{
    const uint lengthOld = s.Length;
    if (lengthNew <= lengthOld)
        return;

    s.Resize(lengthNew);

    for (uint i = lengthOld; i < lengthNew; ++i)
        s[i] = c;
}

String@ StringCopyPadRight(String@ copy, const uint lengthNew, const uint8 c = ' ')
{
    StringPadRight(string(copy), lengthNew, c);
    return copy;
}

void StringPadRightBy(string& s, const uint padBy, const uint8 c = ' ')
{
    StringPadRight(s, s.Length + padBy, c);
}

String@ StringCopyPadRightBy(String@ copy, const uint padBy, const uint8 c = ' ')
{
    StringPadRightBy(string(copy), padBy, c);
    return copy;
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
