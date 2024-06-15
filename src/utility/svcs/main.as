// Version Control System for TMInterface scripts!

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = "script_vcs";
    info.Description = "Script Version Control System";
    info.Version = "v2.1.0";
    return info;
}

void Main()
{
    VCS::Main();
    RegisterCustomCommand("svcs", "Command for script_vcs", OnCommand);
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
