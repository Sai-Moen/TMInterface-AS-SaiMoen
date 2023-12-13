// Preset Settings

const string ID = "pre_settings";
const string NAME = "PreSettings";
const string COMMAND = "ps";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = "Automatically create presets based on certain settings";
    info.Version = "v2.0.1.1";
    return info;
}

void Main()
{
    OnRegister();
    LoadFiles();
    RegisterCustomCommand(COMMAND, "Use: " + COMMAND + " help", OnCommand);
}

void OnDisabled()
{
    StoreFiles();
}

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string ENABLED = PrefixVar("enabled");
const string NEW_FILENAME = PrefixVar("new_filename");
const string CURR_NAME = PrefixVar("curr_name");

bool enabled;
string newFilename;
string currName;

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(NEW_FILENAME, string());
    RegisterVariable(CURR_NAME, string());

    enabled = GetVariableBool(ENABLED);
    newFilename = GetVariableString(NEW_FILENAME);
    currName = GetVariableString(CURR_NAME);
}

const string HELP = "help";
const string TOGGLE = "toggle";

void OnCommand(
    int fromTime,
    int toTime,
    const string &in commandLine,
    const array<string> &in args)
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

const string NEWLINE = "\n";

const string CONFIG_FILENAME = "_";
const string CONFIG_DIRECTORY = ID + "\\";
const string CONFIG_PATH = CONFIG_DIRECTORY + CONFIG_FILENAME;

const string RelativeName(const string &in filename)
{
    return filename.Substr(filename.FindLast(CONFIG_DIRECTORY) + CONFIG_DIRECTORY.Length);
}

void LoadFiles()
{
    CommandList cfg(CONFIG_PATH);
    if (cfg is null)
    {
        CreateFile(CONFIG_PATH);
    }
    else
    {
        const array<string>@ const filenames = cfg.Content.Split(NEWLINE);
        for (uint i = 0; i < filenames.Length; i++)
        {
            const string filename = filenames[i];
            if (filename.IsEmpty()) continue;

            CommandList@ const preset = CommandList(filename);
            if (preset is null) continue;

            @presets[RelativeName(filename)] = preset;
        }

        @curr = GetPreset(currName);
    }
}

void StoreFiles()
{
    CommandList cfg;

    const array<string>@ const keys = presets.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        CommandList@ const preset = GetPreset(key);
        if (preset is null)
        {
            presets.Delete(key);
            continue;
        }

        const string filename = CONFIG_DIRECTORY + key;
        preset.Save(filename);
        cfg.Content += filename + NEWLINE;
    }
    changed = false;

    cfg.Save(CONFIG_PATH);
}

CommandList@ GetPreset(const string &in key)
{
    return cast<CommandList@>(presets[key]);
}

void CreateFile(const string &in filename)
{
    CommandList().Save(filename);
}

bool changed = false;

CommandList@ curr;
dictionary presets;

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
    newFilename = UI::InputTextVar("New Config Name", NEW_FILENAME);
    if (UI::Button("Add New Config") && newFilename != CONFIG_FILENAME)
    {
        const string newPath = CONFIG_DIRECTORY + newFilename;
        CreateFile(newPath);

        CommandList@ const script = CommandList(newPath);
        @presets[newFilename] = script;
        StoreFiles();

        SetVariable(CURR_NAME, currName = newFilename);
        @curr = script;

        SetVariable(NEW_FILENAME, newFilename = string());
    }

    UI::Separator();

    if (UI::Button("Save"))
    {
        StoreFiles();
    }

    if (UI::BeginCombo("Presets", currName))
    {
        const array<string>@ const keys = presets.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            CommandList@ const preset = GetPreset(key);
            if (UI::Selectable(key, preset is curr))
            {
                SetVariable(CURR_NAME, currName = key);
                @curr = preset;
            }
        }

        UI::EndCombo();
    }

    if (curr !is null)
    {
        DrawCurrent();
    }
}

string vars;

void DrawCurrent()
{
    if (UI::Button("Load"))
    {
        if (changed)
        {
            StoreFiles();
        }
        curr.Process();
    }

    if (UI::BeginTable("Settings", 2))
    {
        array<string>@ settings = curr.Content.Split(NEWLINE);

        UI::TableHeadersRow();
        if (UI::Button("New Setting"))
        {
            settings.InsertAt(0, string());
        }

        vars = UI::InputText("Insert vars?", vars);
        if (!vars.IsEmpty())
        {
            @settings = vars.Split(";");
            vars = string();
        }

        const uint noIndex = ~0;
        uint idxAdd = noIndex;
        uint idxDel = noIndex;

        for (uint i = 0; i < settings.Length; i++)
        {
            UI::PushID("TableRow" + i);

            UI::TableNextColumn();
            UI::PushItemWidth(0);

            const string old = settings[i];
            const string new = UI::InputText("", old);
            changed = changed || new != old;
            settings[i] = new;

            UI::PopItemWidth();

            UI::TableNextColumn();
            if (UI::Button("+"))
            {
                idxAdd = i;
            }
            UI::SameLine();
            if (UI::Button("-"))
            {
                idxDel = i;
            }

            UI::PopID();
            UI::TableNextRow();
        }

        if (idxAdd != noIndex)
        {
            settings.InsertAt(idxAdd + 1, string());
        }
        else if (idxDel != noIndex)
        {
            settings.RemoveAt(idxDel);
        }

        if (settings.IsEmpty())
        {
            presets.Delete(currName);
            StoreFiles();

            currName = string();
            @curr = null;
        }
        else
        {
            curr.Content = Text::Join(settings, NEWLINE);
        }

        UI::EndTable();
    }
}
