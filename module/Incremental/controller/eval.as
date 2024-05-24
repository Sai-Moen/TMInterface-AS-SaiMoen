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
    array<InputCommand> inputs;
    SimulationState@ finalState;

    void AddInputCommand(const InputCommand &in cmd)
    {
        inputs.Add(cmd);
    }

    string ToString() const
    {
        string builder;
        if (inputs.IsEmpty()) return builder;

        InputCommand prev = inputs[0];
        builder += prev.ToScript() + "\n";
        for (uint i = 1; i < inputs.Length; i++)
        {
            InputCommand curr = inputs[i];
            if (curr.Type != prev.Type || curr.State != prev.State)
            {
                builder += curr.ToScript() + "\n";
            }
            prev = curr;
        }
        return builder;
    }
}

uint irIndex = 0;
InputsResult@ inputsResult;
array<InputsResult> inputsResults;

void NextRangeTime(SimulationManager@ simManager)
{
    EndRangeTime(simManager);
    @inputsResult = inputsResults[++irIndex];
    Time::Input = Range::Pop();
}

void EndRangeTime(SimulationManager@ simManager)
{
    @inputsResult.finalState = simManager.SaveState();
}

bool up;
bool down;
bool respawn;

void Reset()
{
    cmdlist.Content = "";
    @minState = null;

    irIndex = 0;
    @inputsResult = null;
    inputsResults.Clear();

    up = false;
    down = false;
    respawn = false;
}

void Advance(SimulationManager@ simManager, const int state)
{
    const ms timestamp = Eval::Time::input;
    const InputType type = InputType::Steer;

    const auto@ const buffer = simManager.InputEvents;
    BufferRemoveIndices(buffer, buffer.Find(timestamp, type));

    SaveExistingInput(buffer, timestamp, InputType::Respawn, respawn);
    SaveExistingInput(buffer, timestamp, InputType::Up, up);
    SaveExistingInput(buffer, timestamp, InputType::Down, down);
    buffer.Add(timestamp, type, state);

    InputCommand cmd = MakeInputCommand(timestamp, type, state);
    inputsResult.AddInputCommand(cmd);
    Settings::PrintInfo(simManager, cmd.ToScript());

    Time::Input += TICK;
}

void SaveExistingInput(
    TM::InputEventBuffer@ const buffer,
    const int time,
    const InputType type,
    const bool current)
{
    const int state = current ? 1 : 0;
    if (DiffPreviousInput(buffer, time, type, current))
        inputsResult.AddInputCommand(MakeInputCommand(time, type, state));
}


} // namespace Eval
