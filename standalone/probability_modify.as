// A way to automatically pick an input modify count using a percentage

const string ID = "probability_modify";
const string NAME = "Modification Probability";
const string COMMAND = "toggle_probability_modify";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = "Converts percentage to input modify count";
    info.Version = "v2.0.1.0";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(COMMAND, "Toggles " + NAME + " window", OnCommand);
}

bool enabled = false;

void OnCommand(
    int fromTime,
    int toTime,
    const string &in commandLine,
    const array<string> &in args)
{
    enabled = !enabled;
}

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string PERCENTAGE = PrefixVar("percentage");
double percentage;

void OnRegister()
{
    RegisterVariable(PERCENTAGE, 0.05);
    percentage = GetVariableDouble(PERCENTAGE);
}

const double MIN = 0.0;
const double MAX = 100.0;

void Render()
{
    if (!enabled) return;

    if (UI::Begin(NAME))
    {
        Window();
    }
    UI::End();
}

void Window()
{
    percentage = UI::SliderFloatVar("Input Modify Probability (%)", PERCENTAGE, MIN, MAX, "%.6f");
    percentage = Math::Clamp(percentage, MIN, MAX) / MAX;
    if (percentage == MIN) return;

    const int timeDiff = int(GetVariableDouble("bf_inputs_max_time") - GetVariableDouble("bf_inputs_min_time"));
    if (timeDiff > 0)
    {
        SetVariable("bf_modify_count", Math::Ceil((timeDiff / 10) * percentage));
    }
}
