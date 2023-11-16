// Version Control System for TMInterface!

const string ID      = "script_vcs";
const string NAME    = "TMInterface Script Version Control System";
const string COMMAND = "svcs";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = "Use '" + COMMAND + " help' to see available commands";
    info.Version = "v2.0.1.0";
    return info;
}

void Main()
{
    RegisterCustomCommand(COMMAND, "Command for " + NAME, OnCommand);
}
