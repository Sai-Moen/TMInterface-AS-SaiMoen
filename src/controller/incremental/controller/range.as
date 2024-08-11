namespace Range
{


const string PREFIX = ::PREFIX + "range_";

const string MODE = PREFIX + "mode";

const dictionary map =
{
    {"Speed", Speed},
    {"Horizontal Speed", HSpeed},
    {"Forwards Force", FForce}
};
const array<string> modes = map.GetKeys();

string mode;

funcdef bool IsBetter(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other);
const IsBetter@ isBetter;

void ChangeMode(const string &in newMode)
{
    @isBetter = cast<IsBetter>(map[newMode]);
    SetVariable(MODE, newMode);
    mode = newMode;
}

string GetBestInputs()
{
    const Eval::InputsResult@ best = Eval::inputsResults[0];
    for (uint i = 1; i < Eval::inputsResults.Length; i++)
    {
        Eval::InputsResult@ const other = Eval::inputsResults[i];
        if (other.finalState is null) continue;

        if (best.finalState is null || isBetter(best, other))
        {
            @best = other;
        }
    }
    return best.inputs;
}

bool Speed(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other)
{
    const vec3 vBest = best.finalState.SceneVehicleCar.CurrentLocalSpeed;
    const vec3 vOther = other.finalState.SceneVehicleCar.CurrentLocalSpeed;
    return vOther.LengthSquared() > vBest.LengthSquared();
}

bool HSpeed(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other)
{
    const vec3 vBest = best.finalState.SceneVehicleCar.CurrentLocalSpeed;
    const vec3 vOther = other.finalState.SceneVehicleCar.CurrentLocalSpeed;
    return vOther.x * vOther.z > vBest.x * vBest.z;
}

bool FForce(const Eval::InputsResult@ const best, const Eval::InputsResult@ const other)
{
    const vec3 vBest = best.finalState.SceneVehicleCar.TotalCentralForceAdded;
    const vec3 vOther = other.finalState.SceneVehicleCar.TotalCentralForceAdded;
    return vOther.z > vBest.z;
}

array<ms> startingTimes;
array<TM::InputEvent> startingEvents;
SimulationState@ startingState;

ms Pop()
{
    ms first = startingTimes[0];
    startingTimes.RemoveAt(0);
    return first;
}

void OnBegin(const TM::InputEventBuffer@ const buffer)
{
    // Evaluating in descending order because that's easier to cleanup (do nothing)
    for (ms i = Settings::evalTo; i >= Settings::timeFrom; i -= TICK)
    {
        startingTimes.Add(i);
    }

    const uint len = buffer.Length;
    startingEvents.Resize(len);
    for (uint i = 0; i < len; i++)
    {
        startingEvents[i] = buffer[i];
    }
}

void ApplyStartingEvents(TM::InputEventBuffer@ const buffer)
{
    buffer.Clear();
    const uint len = startingEvents.Length;
    for (uint i = 0; i < len; i++)
    {
        buffer.Add(startingEvents[i]);
    }
}

void Reset()
{
    startingTimes.Clear();
    startingEvents.Clear();
    @startingState = null;
}


} // namespace Range
