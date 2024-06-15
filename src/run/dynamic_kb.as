// KB helpers

const string ID = "dynamic_kb";
const string CMD = "dkb";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Keyboard helpers.";
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(CMD, "Internal " + ID + " command, do not use.", OnDKB);
    RegisterSettingsPage(ID, Window);
}

const int FULLSTEER = 0x10000;

const string PREFIX = ID + "_";

const string ENABLED = PREFIX + "enabled";
bool enabled;

const string SMOOTH_ENABLED = PREFIX + "smooth_enabled";
const string SMOOTH_SIZE    = PREFIX + "smooth_size";
const string SMOOTH_DATA    = PREFIX + "smooth_data";
const string SMOOTH_TREND   = PREFIX + "smooth_trend";

const string AK_ENABLED  = PREFIX + "ak_enabled";
const string AK_REGISTRY = PREFIX + "ak_registry";

const uint MIN_SMOOTH_SIZE = 2;

const string SEP_AK = ",";
const string SEP_AKS = ";";

bool smoothEnabled;
uint smoothSize; uint SmoothSize { set { SetVariable(SMOOTH_SIZE, smoothSize = value); } }
double smoothData;
double smoothTrend;

array<int> inputs;

bool akEnabled;
dictionary akRegistry;

void OnRegister()
{
    RegisterVariable(ENABLED, false);

    RegisterVariable(SMOOTH_ENABLED, false);
    RegisterVariable(SMOOTH_SIZE, 64);
    RegisterVariable(SMOOTH_DATA, 0.2);
    RegisterVariable(SMOOTH_TREND, 0.05);

    RegisterVariable(AK_ENABLED, false);
    RegisterVariable(AK_REGISTRY, "");


    enabled = GetVariableBool(ENABLED);

    smoothEnabled = GetVariableBool(SMOOTH_ENABLED);
    smoothSize = uint(GetVariableDouble(SMOOTH_SIZE));
    inputs.Resize(smoothSize);
    smoothData = GetVariableDouble(SMOOTH_DATA);
    smoothTrend = GetVariableDouble(SMOOTH_TREND);

    akEnabled = GetVariableBool(AK_ENABLED);
    akRegistry = DeserializeRegistry(GetVariableString(AK_REGISTRY));
    ApplyRegistry();
}

uint magnitude = FULLSTEER;

void OnRunStep(SimulationManager@ simManager)
{
    if (!enabled) return;

    int input;
    InputState state = simManager.GetInputState();
    if (state.Left)
    {
        input = -FULLSTEER;
    }
    else if (state.Right)
    {
        input = FULLSTEER;
    }
    else
    {
        input = 0;
    }

    if (smoothEnabled)
    {
        const uint end = smoothSize - 1;
        for (uint i = 0; i < end; i++)
        {
            inputs[i] = inputs[i + 1];
        }
        inputs[end] = input;
        input = DoubleExponentialSmoothing();
    }

    if (akEnabled)
    {
        input = Math::Clamp(input, -magnitude, magnitude);
    }

    simManager.SetInputState(InputType::Steer, input);
}

void OnDKB(int, int, const string &in, const array<string> &in args)
{
    if (args.IsEmpty())
    {
        log("Cannot execute Action Key, args is empty!", Severity::Error);
        return;
    }

    const uint m = Math::Clamp(Text::ParseUInt(args[0]), 0, FULLSTEER);
    magnitude = m != magnitude ? m : FULLSTEER;
}

string keybindName;

void Window()
{
    enabled = UI::CheckboxVar("Enable (and convert steer)", ENABLED);
    UI::BeginDisabled(!enabled);

    UI::Separator();

    smoothEnabled = UI::CheckboxVar("Enable Smoothing?", SMOOTH_ENABLED);
    UI::BeginDisabled(!smoothEnabled);

    const int tempSmoothSize = UI::InputIntVar("Smoothing size (in ticks)", SMOOTH_SIZE);
    SmoothSize = tempSmoothSize < MIN_SMOOTH_SIZE ? MIN_SMOOTH_SIZE : tempSmoothSize;
    inputs.Resize(smoothSize);

    smoothData = UI::SliderFloatVar("Smoothing data factor", SMOOTH_DATA, 0, 1);
    smoothTrend = UI::SliderFloatVar("Smoothing trend factor", SMOOTH_TREND, 0, 1);

    UI::EndDisabled();

    UI::Separator();

    akEnabled = UI::CheckboxVar("Enable Action Keys?", AK_ENABLED);
    UI::BeginDisabled(!akEnabled);

    keybindName = UI::InputText("New keybind name", keybindName);
    if (UI::Button("Add Action Key?"))
    {
        akRegistry[keybindName] = FULLSTEER;
        keybindName = "";
        UpdateRegistry();
    }
    
    if (UI::Button("Rebind"))
    {
        UpdateRegistry();
    }

    UI::Separator();
    const auto@ const keys = akRegistry.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        const uint value = uint(akRegistry[key]);

        UI::Text("Key " + key);
        akRegistry[key] = UI::InputInt("Value " + key, value);

        if (UI::Button("Delete " + key))
        {
            akRegistry.Delete(key);
            UpdateRegistry();
        }

        UI::Separator();
    }

    UI::EndDisabled();


    UI::EndDisabled();
}

// https://en.wikipedia.org/wiki/Exponential_smoothing#Double_exponential_smoothing_(Holt_linear)

array<double> des_s;
array<double> des_b;

int DoubleExponentialSmoothing()
{
    des_s.Resize(smoothSize);
    des_b.Resize(smoothSize);

    des_s[0] = inputs[0];
    des_b[0] = inputs[1] - inputs[0];

    const double invData = 1 - smoothData;
    const double invTrend = 1 - smoothTrend;

    for (uint t = 1; t < smoothSize; t++)
    {
        const double prevS = des_s[t - 1];
        const double prevB = des_b[t - 1];

        des_s[t] = smoothData * inputs[t] + invData * (prevS + prevB);
        des_b[t] = smoothTrend * (des_s[t] - prevS) + invTrend * prevB;
    }

    const int steer = int(des_s[smoothSize - 1]);
    return Math::Clamp(steer, -FULLSTEER, FULLSTEER);
}

string SerializeRegistry(const dictionary@ const registry)
{
    array<string> builder;
    const auto@ const keys = registry.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        builder.Add(key + SEP_AK + uint(registry[key]));
    }
    return Text::Join(builder, SEP_AKS);
}

dictionary@ DeserializeRegistry(const string &in s)
{
    dictionary builder;
    const auto@ const split = s.Split(SEP_AKS);
    for (uint i = 0; i < split.Length; i++)
    {
        const auto@ const keyval = split[i].Split(SEP_AK);
        if (keyval.Length < 2) continue;

        builder[keyval[0]] = Text::ParseUInt(keyval[1]);
    }
    return builder;
}

void UpdateRegistry()
{
    SetVariable(AK_REGISTRY, SerializeRegistry(akRegistry));
    ApplyRegistry();
}

void ApplyRegistry()
{
    const auto@ const keys = akRegistry.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        ExecuteCommand("bind " + key + " \"" + CMD + " " + uint(akRegistry[key]) + "\"");
    }
}
