namespace Core::Run
{


// - General

void SetInput(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
	const uint absoluteTick = MsToTick(time);
    if (absoluteTick >= inputStatesList.Length)
        inputStatesList.Resize(absoluteTick + 1);

    InputStates@ const inputStates = inputStatesList[absoluteTick];
    switch (type)
    {
    case InputType::Down:  inputStates.brake = value; break;
    case InputType::Up:    inputStates.gas   = value; break;
    case InputType::Steer: inputStates.steer = value; break;
    default:
        print("Unsupported InputType for run-mode", Severity::Error);
    break;
    }
}

bool HasInputs(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    const uint index = MsToTick(time);
    if (index >= inputStatesList.Length)
        return false;

    bool hasInputs;
    const auto@ const inputStates = inputStatesList[index];
    switch (type)
    {
    case InputType::None:
        hasInputs =
            HasInputValue(inputStates.brake, inputNeutral.brake, value) ||
            HasInputValue(inputStates.gas,   inputNeutral.gas,   value) ||
            HasInputValue(inputStates.steer, inputNeutral.steer, value);
    break;
    case InputType::Down:
        hasInputs = HasInputValue(inputStates.brake, inputNeutral.brake, value);
    break;
    case InputType::Up:
        hasInputs = HasInputValue(inputStates.gas,   inputNeutral.gas,   value);
    break;
    case InputType::Steer:
        hasInputs = HasInputValue(inputStates.steer, inputNeutral.steer, value);
    break;
    default:
        print("Unsupported InputType in HasInputs", Severity::Error);
   	break;
    }

    return hasInputs;
}

bool HasInputValue(const int inputValue, const int neutral, const int value)
{
    if (inputValue == neutral)
        return false;

    if (value == Math::INT_MAX)
        return true;

    return inputValue == value;
}

void RemoveInputs(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    const uint index = MsToTick(time);
    if (index >= inputStatesList.Length)
        return;

    InputStates@ const inputStates = inputStatesList[index];
    switch (type)
    {
    case InputType::None:
        if (value == Math::INT_MAX)
        {
            inputStatesList[index] = inputNeutral;
        }
        else
        {
            if (inputStates.brake == value) inputStates.brake = inputNeutral.brake;
            if (inputStates.gas   == value) inputStates.gas   = inputNeutral.gas;
            if (inputStates.steer == value) inputStates.steer = inputNeutral.steer;
        }
        break;
    case InputType::Down:
        if (value == Math::INT_MAX || inputStates.brake == value)
            inputStates.brake = inputNeutral.brake;
        break;
    case InputType::Up:
        if (value == Math::INT_MAX || inputStates.gas == value)
            inputStates.gas = inputNeutral.gas;
        break;
    case InputType::Steer:
        if (value == Math::INT_MAX || inputStates.steer == value)
            inputStates.steer = inputNeutral.steer;
        break;
    }
}

void RemoveSteeringAhead(SimulationManager@ sim)
{
    const uint len = inputStatesList.Length;
    for (uint i = MsToTick(tInput); i < len; i++)
        inputStatesList[i].steer = inputNeutral.steer;
}


// - Input States

// mirrors the SceneVehicleCar.Input* properties
class InputStates
{
    int brake = -1;
    int gas   = -1;
    int steer = Math::INT_MIN;
}

const InputStates inputNeutral;

ms runReplayTime;
array<InputStates> inputStatesList;

void InitInputStates()
{
    runReplayTime = Settings::varReplayTime;
    inputStatesList.Resize(MsToTick(runReplayTime));
}

void CollectInputStates(SimulationManager@ sim)
{
    CollectInputStates(sim, sim.TickTime);
}

void CollectInputStates(SimulationManager@ sim, const ms time)
{
    const uint index = MsToTick(time) - 1;
    if (index >= inputStatesList.Length)
        return;

    const auto@ const svc = sim.SceneVehicleCar;

    auto@ const inputStates = inputStatesList[index];
    inputStates.brake = int(svc.InputBrake);
    inputStates.gas   = int(svc.InputGas);
    inputStates.steer = ToSteer(svc.InputSteer);
}

void ApplyInputStates(SimulationManager@ sim)
{
    ApplyInputStates(sim, sim.TickTime);
}

void ApplyInputStates(SimulationManager@ sim, const ms time)
{
    // defer rewinding = false;

    const uint index = MsToTick(time);
    if (index >= inputStatesList.Length)
    {
        rewinding = false;
        return;
    }

    const auto@ const inputStates = inputStatesList[index];
    const InputState oldInputState = sim.GetInputState();
    auto@ const buffer = sim.InputEvents;

    {
        const InputType type = InputType::Down;
        const int value = inputStates.brake;
        if (value != inputNeutral.brake)
        {
            if (rewinding)
            {
                const uint oldLen = buffer.Length;
                sim.SetInputState(type, value);
                const uint newLen = buffer.Length;
                if (oldLen == newLen && oldInputState.Down != sim.GetInputState().Down)
                    buffer.Add(time, type, value);
            }
            else
            {
                sim.SetInputState(type, value);
            }
        }
    }

    {
        const InputType type = InputType::Up;
        const int value = inputStates.gas;
        if (value != inputNeutral.gas)
        {
            if (rewinding)
            {
                const uint oldLen = buffer.Length;
                sim.SetInputState(type, value);
                const uint newLen = buffer.Length;
                if (oldLen == newLen && oldInputState.Up != sim.GetInputState().Up)
                    buffer.Add(time, type, value);
            }
            else
            {
                sim.SetInputState(type, value);
            }
        }
    }

    {
        const InputType type = InputType::Steer;
        const int value = inputStates.steer;
        if (value != inputNeutral.steer)
        {
            if (rewinding)
            {
                const uint oldLen = buffer.Length;
                sim.SetInputState(type, value);
                const uint newLen = buffer.Length;
                if (oldLen == newLen && oldInputState.Steer != sim.GetInputState().Steer)
                    buffer.Add(time, type, value);
            }
            else
            {
                sim.SetInputState(type, value);
            }
        }
    }

    rewinding = false;
}

void ResetInputStates()
{
    runReplayTime = 0;
    inputStatesList.Clear();
}


} // namespace Core::Run
