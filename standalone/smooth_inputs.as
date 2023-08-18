// Smooth inputs 'port', with some creative liberties

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

funcdef void SimStep(SimulationManager@ simManager, bool userCancelled);
const SimStep@ step;

SmoothContext current;
array<SmoothContext> context;

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
    {
        @step = function(simManager, userCancelled) {};
        return;
    }

    @step = OnStep;
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    step(simManager, userCancelled);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    if (IsOtherController()) return;

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

    current = SmoothContext();
    context.Resize(0);
}

bool IsOtherController()
{
    return ID != GetVariableString(CONTROLLER);
}

void OnStep(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled)
    {
        simManager.ForceFinish();
        return;
    }

    const int time = simManager.RaceTime;
    if (time > 0)
    {
        SmoothContext ctx;
        ctx.time = time - 10;
        ctx.steer = DetermineSteer(simManager);

        const auto@ const buffer = simManager.InputEvents;
        ctx.respawn = BufferGetBinary(buffer, ctx.time, InputType::Respawn, current.respawn);
        ctx.up = BufferGetBinary(buffer, ctx.time, InputType::Up, current.up);
        ctx.down = BufferGetBinary(buffer, ctx.time, InputType::Down, current.down);

        current = ctx;
        context.Add(ctx);
    }
}

int DetermineSteer(SimulationManager@ simManager)
{
    const auto@ const svc = simManager.SceneVehicleCar;

    const float inputSteer = svc.InputSteer;
    int steer = NextTurningRate(inputSteer, svc.TurningRate);
    if (IsAirtime(simManager))
    {
        const Signum sign = Sign(inputSteer);
        if (sign == Signum::Zero)
        {
            steer = 0;
        }
        else
        {
            float steerf = steer;
            while (sign != Sign(steerf))
            {
                steerf += sign * STEER::RATE_F;
            }
            steer = RoundAway(steerf, sign);
        }
    }
    return steer; // Shouldn't need to clamp it since NextTurningRate is implicitly clamped...
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

const string ToScript()
{
    string script = "";

    SmoothContext prev();
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

    int steer;
    bool respawn;
    bool up;
    bool down;

    void opAssign(const SmoothContext &in other)
    {
        time = other.time;

        steer = other.steer;
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

        if (steer != previous.steer)
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
    const int HALF = FULL >> 1;
    const int MIN  = -FULL;
    const int MAX  = FULL;

    const float RATE_F = .2f;
}

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER::MIN, STEER::MAX);
}

float ClampTurningRate(const float inputSteer, const float turningRate)
{
    return Math::Clamp(inputSteer, turningRate - STEER::RATE_F, turningRate + STEER::RATE_F);
}

int NextTurningRate(const float inputSteer, const float turningRate)
{
    const float magnitude = ClampTurningRate(inputSteer, turningRate) * STEER::FULL;
    const float direction = magnitude - turningRate * STEER::FULL;
    return RoundAway(magnitude, direction);
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
    default: return 0; // Unreachable :Clueless:
    }
}

int RoundAway(const float magnitude, const float direction)
{
    return RoundAway(magnitude, Sign(direction));
}
