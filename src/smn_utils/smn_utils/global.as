/*

smn_utils | Global namespace | v3.0.0

Features:
- Var Get/Set Wrappers.
- Extra log/print overloads.
- TM namespace adjacent.
- Things that have to be set through vars for some reason (or forgot to remove them if they were added).

*/


//- Var

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


//- Log

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


//- Print

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


//- TM-adjacent

InputType EventIndexToInputType(const EventIndices &in eventIndices, const int8 eventIndex)
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
array<InputType>@ EventIndicesMapping(const EventIndices &in eventIndices)
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
        const int id = ids[i];
        if (capacity <= id)
            capacity = id + 1;
    }

    array<InputType> mapping(capacity);
    for (uint i = 0; i < idsLen; ++i)
    {
        const int id = ids[i];
        if (id != -1)
            mapping[id] = InputType(i);
    }
    return mapping;
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

// SetInputState, but asserts that it does not add an input event.
void ModifyInputState(SimulationManager@ sim, InputType state, int value)
{
    const auto@ const buffer = sim.InputEvents;
    const uint lengthOld = buffer.Length;
    sim.SetInputState(state, value);
    const uint lengthNew = buffer.Length;
    Assert(lengthOld == lengthNew);
}

// Run-mode only: SetInputState for each event in the IEB at RaceTime.
void ApplyInputStates(SimulationManager@ sim)
{
    ApplyInputStates(sim, BufferFindTime(sim.InputEvents, sim.RaceTime, -1));
}

// Run-mode only: SetInputState for each event in the IEB at RaceTime, with a given starting index.
void ApplyInputStates(SimulationManager@ sim, const uint index)
{
    auto@ const buffer = sim.InputEvents;
    const uint bufferLen = buffer.Length;
    if (index >= bufferLen)
        return;

    const ums timestamp = sim.RaceTime + IEB_TIME_OFFSET;
    const array<InputType>@ mapping = EventIndicesMapping(buffer.EventIndices);
    for (uint i = index; i < bufferLen; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Time != timestamp)
            break;

        TM::InputEventValue inputEventValue = inputEvent.Value;
        const InputType state = mapping[inputEventValue.EventIndex];
        ModifyInputState(sim, state, InputEventValueToInt(inputEventValue, state));
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

// Rewind, but remove input events starting from 'state' RaceTime.
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


//- Misc

void DrawGame(const bool value)
{
    SetVariable("draw_game", value);
}
