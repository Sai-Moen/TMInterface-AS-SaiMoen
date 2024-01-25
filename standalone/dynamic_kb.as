// Interpret keyboard input as rolling average pad input

const string ID = "dynamic_kb";
const string CMD = "dkb";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Dynamically interprets keyboard input as rolling average pad input.";
    info.Version = "v2.0.1.0";
    return info;
}

const int FULLSTEER = 0x10000;

const uint SIZE = 10;
array<int> inputs;

void Main()
{
    inputs = array<int>(SIZE);
    RegisterCustomCommand(CMD, ID, OnDKB);
}

bool enabled = false;

void OnDKB(int fromTime, int toTime, const string &in commandLine, const array<string> &in args)
{
    if (args.IsEmpty())
    {
        enabled = !enabled;
        return;
    }

    if (args.Length < 2)
    {
        log("Not enough args!", Severity::Warning);
        return;
    }

    if (args[0] == "data")
    {
        double d;
        if (TryParseDouble(args[1], d))
        {
            SMOOTH_DATA = d;
            log("Data Smoothing = " + SMOOTH_DATA);
        }
    }
    else if (args[0] == "trend")
    {
        double d;
        if (TryParseDouble(args[1], d))
        {
            SMOOTH_TREND = d;
            log("Trend Smoothing = " + SMOOTH_TREND);
        }
    }
}

bool TryParseDouble(const string &in s, double &out d)
{
    uint byteCount;
    d = Text::ParseFloat(s, byteCount);
    if (byteCount == 0)
    {
        log("Could not parse number", Severity::Error);
        return false;
    }
    return true;
}

void OnRunStep(SimulationManager@ simManager)
{
    if (!enabled) return;

    InputState state = simManager.GetInputState();
    if (state.Left)
    {
        inputs.Add(-FULLSTEER);
    }
    else if (state.Right)
    {
        inputs.Add(FULLSTEER);
    }
    else
    {
        inputs.Add(0);
    }

    if (inputs.Length > SIZE)
    {
        inputs.RemoveAt(0, inputs.Length - SIZE);
    }

    simManager.SetInputState(InputType::Steer, DoubleExponentialSmoothing());
}

// https://en.wikipedia.org/wiki/Exponential_smoothing#Double_exponential_smoothing_(Holt_linear)

double SMOOTH_DATA = 1.0 / SIZE;
double SMOOTH_TREND = 1.0 / SIZE;

int DoubleExponentialSmoothing()
{
    int steer = int(DES_s(inputs.Length - 1));
    return Math::Clamp(steer, -FULLSTEER, FULLSTEER);
}

double DES_s(const uint index)
{
    double iter = inputs[0];
    for (uint i = 1; i < index; i++)
    {
        iter += DES_b(i - 1);
        iter *= 1 - SMOOTH_DATA;
        iter += inputs[i] * SMOOTH_DATA;
    }
    return iter;
}

double DES_b(const uint index)
{
    double iter = inputs[1] - inputs[0];
    for (uint i = 1; i < index; i++)
    {
        iter *= 1 - SMOOTH_TREND;
        iter += (DES_s(i) - DES_s(i - 1)) * SMOOTH_TREND;
    }
    return iter;
}
