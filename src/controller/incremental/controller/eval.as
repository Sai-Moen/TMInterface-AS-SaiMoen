namespace Eval
{


CommandList cmdlist;

SimulationState@ minState; // The state saved when time equals min
SimulationState@ const MinState { get { return minState; } }

void Rewind(SimulationManager@ simManager)
{
    simManager.RewindToState(minState);
}

namespace Time
{
    ms pre;   // When to save a state for a starting timerange
    ms min;   // When to save a state in order to be able to rewind to input time
    ms input; // When to do inputs for this iteration
    ms eval;  // When to check the results of a sub-iteration,
                // may change within an iteration, but that is up to the implementing mode(s)
    ms max;   // The maximum time at which an input has been added (used for cleanup)

    ms Input
    {
        get { return input; }
        set
        {
            min = value - TICK;
            input = value;
        }
    }

    ms Eval
    {
        set { eval = value; }
    }

    void OffsetEval(const ms evalOffset)
    {
        Eval = input + evalOffset;
    }
}

bool BeforeRange(const ms time)
{
    return time < Time::pre;
}

bool BeforeInput(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (time < Time::min) return true;
    else if (time == Time::min)
    {
        @minState = simManager.SaveState();
        return true;
    }
    return false;
}

bool IsInputTime(const ms time)
{
    return time == Time::input;
}

bool IsEvalTime(const ms time)
{
    return time == Time::eval;
}

bool LimitExceeded()
{
    return Time::input > Settings::timeTo;
}

bool OutOfBounds(const ms time)
{
    return minState is null && time > Time::min;
}

class InputsResult
{
    string inputs;
    SimulationState@ finalState;
}

uint irIndex = 0;
InputsResult@ inputsResult;
array<InputsResult> inputsResults;

void AddInput(SimulationManager@ simManager, int time, InputType type, int value)
{
    AddInput(simManager.InputEvents, time, type, value);
}

void AddInput(TM::InputEventBuffer@ const buffer, int time, InputType type, int value)
{
    if (time > Time::max)
        Time::max = time;

    const auto indices = buffer.EventIndices;
    TM::InputEventValue eventValue;
    switch (type)
    {
    case InputType::Steer:
        eventValue.EventIndex = indices.SteerId;
        eventValue.Analog = value;
        break;
    default:
        log("Unknown type being added...", Severity::Error);
        return;
    }

    TM::InputEvent event;
    event.Time = time + 100010;
    event.Value = eventValue;

    buffer.Add(event);
}

void Advance(SimulationManager@ simManager, const int state)
{
    const ms timestamp = Time::input;
    const InputType type = InputType::Steer;

    auto@ const buffer = simManager.InputEvents;
    BufferRemoveIndices(buffer, buffer.Find(timestamp, type));
    AddInput(buffer, timestamp, type, state); // workaround for TM::InputEventBuffer::Add

    InputCommand cmd = MakeInputCommand(timestamp, type, state);
    Settings::PrintInfo(simManager, cmd.ToScript());

    Time::Input += TICK;
}

void NextRangeTime(SimulationManager@ simManager)
{
    EndRangeTime(simManager);
    @inputsResult = inputsResults[++irIndex];
    Time::Input = Range::Pop();
}

void EndRangeTime(SimulationManager@ simManager)
{
    auto@ const buffer = simManager.InputEvents;
    BufferRemoveAllExceptFirst(buffer, Time::input, Time::max, InputType::Steer);
    Time::max = 0;
    inputsResult.inputs = buffer.ToCommandsText();

    @inputsResult.finalState = simManager.SaveState();
}

void Reset()
{
    cmdlist = CommandList();
    @minState = null;

    irIndex = 0;
    @inputsResult = null;
    inputsResults.Clear();
}


} // namespace Eval
