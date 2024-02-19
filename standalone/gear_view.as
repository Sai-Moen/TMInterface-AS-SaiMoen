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
const string SCALE = PREFIX + "scale";

bool enabled;
float scale;

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(SCALE, 80);

    enabled = GetVariableBool(ENABLED);
    scale = GetVariableDouble(SCALE);
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
        Draw(svc);
    }
    UI::End();
}

const uint MAX_GEAR = 5;
uint prevGear;

float prevRPM;
float baseRPM;

void Draw(const TM::SceneVehicleCar@ const svc)
{
    const auto@ const engine = svc.CarEngine;

    scale = UI::InputFloatVar("Scale", SCALE);

    UI::Separator();

    UI::SliderInt("Rear Gear", -engine.RearGear, -1, 0);
    UI::SliderFloat("Real Speed", svc.CurrentLocalSpeed.Length() * 3.6, 0, svc.MaxLinearSpeed * 3.6);

    const float rpm = engine.ActualRPM;
    const float max = engine.MaxRPM;
    const uint gear = engine.Gear;
    if (gear != prevGear && rpm < prevRPM)
    {
        baseRPM = gear > 1 ? rpm : 0;
        prevGear = gear;
    }
    prevRPM = rpm;

    UI::Separator();

    UI::SliderFloat("RPM", rpm, 0, max);
    if (UI::BeginTable("Gears", MAX_GEAR))
    {
        UI::TableSetupScrollFreeze(MAX_GEAR, 1);

        for (uint g = 1; g <= MAX_GEAR; g++)
        {
            UI::TableNextColumn();

            float relRPM = 0;
            float relBaseRPM = 0;
            if (gear > g) relRPM = max;
            else if (gear == g)
            {
                relRPM = rpm;
                relBaseRPM = baseRPM;
            }

            UI::PushItemWidth(scale);
            UI::SliderFloat("", relRPM, relBaseRPM, max);
            UI::PopItemWidth();
        }

        UI::EndTable();
    }
}
