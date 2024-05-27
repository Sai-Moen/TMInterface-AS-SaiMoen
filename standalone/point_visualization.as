// Point Visualization

const string ID = "point_visualization";
const string CMD = "view_point";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Visualize Point";
    info.Version = "v2.0.1.0";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(CMD, "Use: " + CMD + " help", OnCommand);
}

const int INVALID_ID = -1;

void OnDisabled()
{
    if (id != INVALID_ID)
    {
        RemoveTrigger(id);
        id = INVALID_ID;
    }
}

const string PREFIX = ID + "_";

const string ENABLED = PREFIX + "enabled";
const string SIZE = PREFIX + "size";

bool enabled;
vec3 diameter;
vec3 radius;
vec3 Size { set { diameter = value; radius = value / 2; } }

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(SIZE, 1);

    enabled = GetVariableBool(ENABLED);
    Size = vec3(GetVariableDouble(SIZE));
}

namespace cmd
{
    const string HELP = "help";
    const string TOGGLE = "toggle";
    const string REFRESH = "refresh";
    const string SIZE = "size";
}

void OnCommand(int, int, const string &in, const array<string> &in args)
{
    if (args.IsEmpty())
    {
        LogHelp(Severity::Warning);
        return;
    }

    const string cmd = args[0];
    if (cmd == cmd::HELP)
    {
        LogHelp();
    }
    else if (cmd == cmd::TOGGLE)
    {
        OnCommandToggle();
    }
    else if (cmd == cmd::REFRESH)
    {
        OnCommandRefresh();
    }
    else if (cmd == cmd::SIZE)
    {
        OnCommandSize(args, cmd);
    }
    else
    {
        LogHelp(Severity::Error);
    }
}

void LogHelp(Severity severity = Severity::Info)
{
    log("Available Commands:", severity);
    log(cmd::HELP + " - log this help message", severity);
    log(cmd::TOGGLE + " - toggles visualization", severity);
    log(cmd::REFRESH + " - resets trigger (can be useful if you removed it)", severity);
    log(cmd::SIZE + " - changes the size of the point representation", severity);
}

void OnCommandToggle()
{
    SetVariable(ENABLED, enabled = !enabled);
    log("Toggled point visualization to: " + enabled, Severity::Success);
}

void OnCommandRefresh()
{
    if (!GetTrigger(id)) id = INVALID_ID;
}

void OnCommandSize(const array<string> &in args, const string &in cmd)
{
    if (args.Length <= 1)
    {
        log("Syntax: " + cmd + " " + cmd::SIZE + " <number>", Severity::Error);
        return;
    }

    const string arg = args[1];

    uint byteCount;
    const double parsed = Text::ParseFloat(arg, byteCount);
    if (byteCount == 0)
    {
        log("Could not parse number!", Severity::Error);
        return;
    }

    SetVariable(SIZE, parsed);
    log("Set size to: " + parsed, Severity::Success);
    Size = vec3(parsed);
}

vec3 position;
int id = INVALID_ID;

void Render()
{
    if (enabled)
    {
        const vec3 updated = Text::ParseVec3(GetVariableString("bf_target_point")) - radius;
        if (position != updated || id == INVALID_ID)
        {
            position = updated;
            const int temp = SetTrigger(Trigger3D(position, diameter), id);
            if (temp != INVALID_ID) id = temp; // temporary check because of unintended SetTrigger behavior
        }
    }
    else
    {
        OnDisabled();
    }
}
