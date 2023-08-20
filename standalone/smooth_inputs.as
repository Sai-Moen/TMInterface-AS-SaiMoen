// Smooth inputs

const string ID = "simu_smooth_inputs";
const string NAME = "Inputs Smoother";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = "Minimizes inputs to their absolute perfect state (least jitter)";
    info.Version = "v2.0.0.0";
    return info;
}

void Main()
{
    OnRegister();
    RegisterValidationHandler(ID, NAME, OnSettings);
}

const string CONTROLLER = "controller";

bool IsOtherController()
{
    return ID != GetVariableString(CONTROLLER);
}

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string SAVEFILE = PrefixVar("savefile");
string savefile;

void OnRegister()
{
    RegisterVariable(SAVEFILE, ID + ".txt");
    savefile = GetVariableString(SAVEFILE);
}

void OnSettings()
{
    savefile = UI::InputTextVar("File to save to", SAVEFILE);
}

int duration;
array<SmoothContext> context;

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
    {
        @step = function(simManager, userCancelled) {};
        @end = function(simManager, result) {};
        return;
    }

    @step = OnStep;
    @end = OnEnd;

    duration = simManager.EventsDuration;
    context.Resize((duration + 10) / 10);
}

funcdef void SimStep(SimulationManager@ simManager, bool userCancelled);
const SimStep@ step;

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    step(simManager, userCancelled);
}

funcdef void SimEnd(SimulationManager@ simManager, SimulationResult result);
const SimEnd@ end;

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    end(simManager, result);
}

void OnStep(SimulationManager@ simManager, bool userCancelled)
{
    const int time = simManager.RaceTime;
    if (userCancelled || time > duration)
    {
        simManager.ForceFinish();
        return;
    }
    else if (time >= 0)
    {
        const uint index = time / 10;
        context[index].time = time;

        const bool indexGreaterEquals1 = index >= 1;
        const bool indexGreaterEquals2 = index >= 2;

        const auto@ const buffer = simManager.InputEvents;
        SmoothContext prev = indexGreaterEquals1 ? context[index - 1] : SmoothContext();
        context[index].respawn = BufferGetBinary(buffer, time, InputType::Respawn, prev.respawn);
        context[index].up = BufferGetBinary(buffer, time, InputType::Up, prev.up);
        context[index].down = BufferGetBinary(buffer, time, InputType::Down, prev.down);

        const auto@ const svc = simManager.SceneVehicleCar;

        if (indexGreaterEquals1)
        {
            context[index - 1].inputSteer = svc.InputSteer;
            context[index - 1].airtime = IsAirtime(simManager);
        }

        if (indexGreaterEquals2)
        {
            context[index - 2].turningRate = svc.TurningRate;
        }
    }
}

bool BufferGetBinary(
    TM::InputEventBuffer@ const buffer,
    const int time,
    const InputType type,
    const bool current)
{
    const auto@ const indices = buffer.Find(time, type);
    if (indices.IsEmpty()) return current;

    return buffer[indices[indices.Length - 1]].Value.Binary;
}

void OnEnd(SimulationManager@ simManager, SimulationResult result)
{
    CommandList output;
    output.Content = ToScript();
    if (output.Save(savefile))
    {
        log("Saved!", Severity::Success);
    }
    else
    {
        log("Could not save!", Severity::Error);
    }

    context.Resize(0);
}

const string ToScript()
{
    string script = "";

    SmoothContext prev;
    for (uint i = 0; i < context.Length; i++)
    {
        const SmoothContext curr = context[i];
        script += curr.ToScript(prev);
        prev = curr;
    }

    return script;
}

class SmoothContext
{
    int time;

    float inputSteer;
    float turningRate;
    bool airtime;

    bool respawn;
    bool up;
    bool down;

    SmoothContext()
    {
        time = -1;
    }

    void opAssign(const SmoothContext &in other)
    {
        time = other.time;

        inputSteer = other.inputSteer;
        turningRate = other.turningRate;
        airtime = other.airtime;

        respawn = other.respawn;
        up = other.up;
        down = other.down;
    }

    const string ToScript(const SmoothContext &in previous) const
    {
        string script = "";

        if (respawn != previous.respawn)
        {
            script += time + PressOrRel(respawn) + "enter\n";
        }

        if (up != previous.up)
        {
            script += time + PressOrRel(up) + "up\n";
        }

        if (down != previous.down)
        {
            script += time + PressOrRel(down) + "down\n";
        }

        const int NO_STEER = Math::INT_MAX;

        int steer = NO_STEER;
        if (airtime && inputSteer != previous.turningRate)
        {
            steer = ToSteer(inputSteer);
        }
        else if (turningRate < previous.turningRate)
        {
            steer = ToSteerFloor(turningRate);
        }
        else if (turningRate > previous.turningRate)
        {
            steer = ToSteerCeil(turningRate);
        }

        if (steer != NO_STEER)
        {
            script += time + " steer " + steer + "\n";
        }

        return script;
    }
}

const string PressOrRel(const bool pressed)
{
    return pressed ? " press " : " rel ";
}

bool IsAirtime(SimulationManager@ simManager)
{
    //const auto@ const state = simManager.SaveState();
    //const auto@ const wheels = state.Wheels;
    return CountWheelsOnGround(simManager) < 3;
}

uint CountWheelsOnGround(SimulationManager@ simManager)
{
    uint count = 0;

    const auto@ const state = simManager.SaveState();
    const auto@ const wheels = state.Wheels;
    if (wheels.FrontLeft.RTState.HasGroundContact) count++;
    if (wheels.FrontRight.RTState.HasGroundContact) count++;
    if (wheels.BackRight.RTState.HasGroundContact) count++;
    if (wheels.BackLeft.RTState.HasGroundContact) count++;

    return count;
}

namespace STEER
{
    const int FULL = 0x10000;
}

// DO NOT USE TO TRUNCATE SIGNIFICAND/MANTISSA
int ToSteer(const float small)
{
    return int(small * STEER::FULL);
}

int ToSteerFloor(const float small)
{
    return int(Math::Floor(small * STEER::FULL));
}

int ToSteerCeil(const float small)
{
    return int(Math::Ceil(small * STEER::FULL));
}
