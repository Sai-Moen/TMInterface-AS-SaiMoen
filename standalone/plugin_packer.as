// Allows you to pack and unpack plugins more easily

const string ID = "plugin_packer";
const string NAME = "Plugin Packer";
const string COMMAND = "packer";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = NAME;
    info.Version = "v2.0.1.0";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(COMMAND, "Use: " + COMMAND + " help", OnCommand);
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
    log("Available commands:");
    log(HELP + "   - log this message");
    log(TOGGLE + " - toggle the editor");
}

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
}
