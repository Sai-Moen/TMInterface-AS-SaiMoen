// Text editor plugin for TMInterface!

const string ID = "repp";
const string NAME = "RunEditor++";
const string COMMAND = "repp";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = NAME;
    info.Version = "v2.0.1.3";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(COMMAND, "Use: " + COMMAND + " help", OnCommand);
}

void OnDisabled()
{
    editor::OnDisabled();
    presettings::OnDisabled();
}

const string PREFIX = ID + "_";

const string ENABLED = PREFIX + "enabled";
bool enabled;

void OnRegister()
{
    RegisterVariable(ENABLED, false);

    editor::OnRegister();
    presettings::OnRegister();

    enabled = GetVariableBool(ENABLED);
}

const string HELP = "help";
const string TOGGLE = "toggle";
const string EDITOR = editor::ID;

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
    else if (cmd == EDITOR)
    {
        editor::OnCommand(args);
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
    log(EDITOR + " - use editor commands");
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
    if (UI::BeginTabBar("Components"))
    {
        TabItemHelper(editor::NAME, editor::Draw);
        TabItemHelper(presettings::NAME, presettings::Draw);

        UI::EndTabBar();
    }
}
