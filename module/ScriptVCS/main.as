// Version Control System for TMInterface!

const string ID      = "script_vcs";
const string NAME    = "Script Version Control System";
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
    VCS::Main();
}

void Render()
{
    Interface::Render();
}

// Maybe use smn_utils for this
namespace Dictionary
{
    funcdef void Iter(const dictionary@ const d, const string &in key);

    void ForEach(const dictionary@ const d, const Iter@ const funci)
    {
        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            funci(d, keys[i]);
        }
    }

    funcdef dictionaryValue IterVal(const dictionary@ const d, const string &in key);

    array<dictionaryValue>@ ForEachArr(const dictionary@ const d, const IterVal@ const funcival)
    {
        array<dictionaryValue> values(d.GetSize());

        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            values[i] = funcival(d, keys[i]);
        }

        return values;
    }

    dictionary@ ForEachDict(const dictionary@ const d, const IterVal@ const funcival)
    {
        dictionary values;

        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            values[key] = funcival(d, key);
        }

        return values;
    }
}
