// Interpret keyboard input as rolling average pad input

const string ID = "dynamic_kb";
const string CMD = "dkb";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Dynamically interprets keyboard input as rolling average pad input.";
    info.Version = "v2.0.1.1";
    return info;
}

const int FULLSTEER = 0x10000;

void Main()
{
    RegisterCustomCommand(CMD, ID, OnDKB);
}

bool enabled = false;

void OnDKB(int, int, const string &in, const array<string> &in args)
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

    const string mode = args[0];
    if (mode == "data")
    {
        double d;
        if (TryParseDouble(args[1], d))
        {
            SMOOTH_DATA = d;
            log("Data Smoothing = " + SMOOTH_DATA);
        }
        else
        {
            log("Could not parse number", Severity::Error);
        }
    }
    else if (mode == "trend")
    {
        double d;
        if (TryParseDouble(args[1], d))
        {
            SMOOTH_TREND = d;
            log("Trend Smoothing = " + SMOOTH_TREND);
        }
        else
        {
            log("Could not parse number", Severity::Error);
        }
    }
}

bool TryParseDouble(const string &in s, double &out d)
{
    uint byteCount;
    d = Text::ParseFloat(s, byteCount);
    return byteCount != 0;
}

const uint SIZE = 64;
array<int> inputs(SIZE);

void OnRunStep(SimulationManager@ simManager)
{
    if (!enabled) return;

    InputState state = simManager.GetInputState();
    if (state.Left)
    {
        RotateInto(-FULLSTEER);
    }
    else if (state.Right)
    {
        RotateInto(FULLSTEER);
    }
    else
    {
        RotateInto(0);
    }

    simManager.SetInputState(InputType::Steer, DoubleExponentialSmoothing());
}

void RotateInto(const int input)
{
    const uint end = SIZE - 1;
    for (uint i = 0; i < end; i++)
    {
        inputs[i] = inputs[i + 1];
    }
    inputs[end] = input;
}

// https://en.wikipedia.org/wiki/Exponential_smoothing#Double_exponential_smoothing_(Holt_linear)

double SMOOTH_DATA = 0.2;
double SMOOTH_TREND = 0.05;

int DoubleExponentialSmoothing()
{
    DES_wipe(s_state);
    s_tabulation.Resize(SIZE);

    DES_wipe(b_state);
    b_tabulation.Resize(SIZE);

    const int steer = int(DES_s(inputs.Length - 1));
    return Math::Clamp(steer, -FULLSTEER, FULLSTEER);
}

void DES_wipe(array<bool>@ const b)
{
    b.Resize(SIZE);
    for (uint i = 0; i < SIZE; i++)
    {
        b[i] = false;
    }
}

array<bool> s_state;
array<double> s_tabulation;

double DES_s(const uint index)
{
    if (s_state[index]) return s_tabulation[index];

    double iter = inputs[0];
    for (uint i = 1; i < index; i++)
    {
        iter += DES_b(i - 1);
        iter *= 1 - SMOOTH_DATA;
        iter += inputs[i] * SMOOTH_DATA;
    }

    s_state[index] = true;
    return s_tabulation[index] = iter;
}

array<bool> b_state;
array<double> b_tabulation;

double DES_b(const uint index)
{
    if (b_state[index]) return b_tabulation[index];

    double iter = inputs[1] - inputs[0];
    for (uint i = 1; i < index; i++)
    {
        iter *= 1 - SMOOTH_TREND;
        iter += (DES_s(i) - DES_s(i - 1)) * SMOOTH_TREND;
    }

    b_state[index] = true;
    return b_tabulation[index] = iter;
}
