// Widget that displays gear info...

const string ID = "gear_view";
const string NAME = "Gear View";
const string CMD = "gearview";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Can display gear information";
    info.Version = "v2.0.1.0";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(CMD, "Use: " + CMD + " help", OnCommand);
}

const string PREFIX = ID + "_";

const string ENABLED = PREFIX + "enabled";

bool enabled;

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    enabled = GetVariableBool(ENABLED);
}

const string HELP = "help";
const string TOGGLE = "toggle";

void OnCommand(int, int, const string &in, const array<string> &in args)
{
    if (args.IsEmpty())
    {
        LogHelp();
        return;
    }

    const string cmd = args[0];
    if (cmd == HELP)
    {
        LogHelp();
    }
    else if (cmd == TOGGLE)
    {
        SetVariable(ENABLED, enabled = !enabled);
    }
    else
    {
        LogHelp();
    }
}

void LogHelp()
{
    log("Available Commands:");
    log(HELP + " - log this message");
    log(TOGGLE + " - show UI");
}

void Render()
{
    if (!enabled) return;

    const auto@ const svc = GetSimulationManager().SceneVehicleCar;
    if (svc is null) return;

    if (UI::Begin(NAME))
    {
        Draw(svc.CarEngine);
    }
    UI::End();
}

void Draw(const TM::SceneVehicleCar::Engine@ const engine)
{
    UI::SliderInt("Gear", engine.Gear, 0, 5);
    UI::SliderInt("RearGear", -engine.RearGear, -1, 0);

    UI::SliderFloat("ActualRPM", engine.ActualRPM, 0, engine.MaxRPM);
    UI::SliderFloat("ClampedRPM", engine.ClampedRPM, 0, engine.MaxRPM);

    UI::SliderFloat("SlideFactor", engine.SlideFactor, 0.5, 1.5);
    UI::SliderFloat("BrakingFactor", engine.BrakingFactor, -1, 0);
}
