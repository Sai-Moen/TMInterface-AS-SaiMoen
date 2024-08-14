namespace Eval
{


CommandList cmdlist;

SimulationState@ minState; // the state saved when time equals min
SimulationState@ const MinState { get { return minState; } }

void Rewind(SimulationManager@ simManager)
{
    simManager.RewindToState(minState);
}

SimulationState@ inputState; // the state saved when a certain input time is hit for the first time

namespace Time
{
    ms pre;   // When to save a state for a starting timerange
    ms min;   // When to save a state in order to be able to rewind to input time
    ms input; // When to do inputs for this iteration
    ms eval;  // When to check the results of a sub-iteration,
                // may change within an iteration, but that is up to the implementing mode(s)
    ms max;   // Gets set to timeTo if it is a sane value, otherwise duration.
    ms post;  // The maximum time at which an input has been added (used for cleanup)

    ms Input
    {
        get { return input; }
        set
        {
            min = value - TICK;
            input = value;
        }
    }

    void OffsetEval(const ms evalOffset)
    {
        eval = input + evalOffset;
    }
}

bool BeforeRange(const ms time)
{
    return time < Time::pre;
}

bool BeforeInput(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (time < Time::min)
    {
        return true;
    }
    else if (time == Time::min)
    {
        @minState = simManager.SaveState();
        return true;
    }
    else if (time == Time::input && inputState is null)
    {
        @inputState = simManager.SaveState();
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
    return Time::input > Time::max;
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

void AddInput(SimulationManager@ simManager, const ms time, const InputType type, const int value)
{
    AddInput(simManager.InputEvents, time, type, value);
}

void AddInput(TM::InputEventBuffer@ const buffer, const ms time, const InputType type, const int value)
{
    if (Time::post < time)
        Time::post = time;
    buffer.Add(time, type, value);
}

void RemoveInputs(SimulationManager@ simManager, const ms time, const InputType type)
{
    RemoveInputs(simManager.InputEvents, time, type);
}

void RemoveInputs(TM::InputEventBuffer@ const buffer, const ms time, const InputType type)
{
    BufferRemoveIndices(buffer, buffer.Find(time, type));
}

void Advance(SimulationManager@ simManager, const int value)
{
    const ms time = Time::input;

    auto@ const buffer = simManager.InputEvents;
    RemoveInputs(buffer, time, InputType::Steer);
    AddInput(buffer, time, InputType::Steer, value);

    InputCommand cmd = MakeInputCommand(time, InputType::Steer, value);
    Settings::PrintInfo(inputState, cmd.ToScript());

    AdvanceNoCleanup();
}

void AdvanceNoAdd(SimulationManager@ simManager)
{
    const ms time = Time::input;

    auto@ const buffer = simManager.InputEvents;
    RemoveInputs(buffer, time, InputType::Steer);

    AdvanceNoCleanup();
}

void AdvanceNoCleanup()
{
    @inputState = null;
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
    BufferRemoveAll(buffer, Time::input, Time::post, InputType::Steer);
    Time::post = 0;
    inputsResult.inputs = buffer.ToCommandsText();

    @inputsResult.finalState = simManager.SaveState();
}

void Reset()
{
    cmdlist = CommandList();
    @minState = null;
    @inputState = null;

    irIndex = 0;
    @inputsResult = null;
    inputsResults.Clear();
}


} // namespace Eval
