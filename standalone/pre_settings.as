// A way to automatically pick an input modify count using a percentage

const string ID = "pre_settings";
const string NAME = "PreSettings";
const string COMMAND = "ps";

const string HELP = "help";
const string TOGGLE = "toggle";
const string LOAD_VARS = "load_vars";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = "Automatically create presets based on certain settings";
    info.Version = "v2.0.1.0";
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

void OnCommand(
    int fromTime,
    int toTime,
    const string &in commandLine,
    const array<string> &in args)
{
    if (args.Length < 1 || args[0] == "help")
    {
        log("Available Commands:");
        log(HELP + " - log this message");
        log(TOGGLE + " - show UI");
        log(LOAD_VARS + "- paste vars into this to copy into currently selected tab");
        return;
    }
    
    if (args[0] == TOGGLE)
    {
        SetVariable(ENABLED, !enabled);
        enabled = GetVariableBool(ENABLED);
    }
    else if (args[0] == LOAD_VARS)
    {
        if (args.Length < 2)
        {
            log("use `vars` to copy the vars, then paste them as a second argument with \"\"", Severity::Error);
            return;
        }
        else if (curr is null)
        {
            log("no file selected", Severity::Warning);
            return;
        }

        array<string> args2(args.Length - 1);
        for (uint i = 1; i < args.Length; i++)
        {
            args2[i] = args[i - 1];
        }

        const string vars = Text::Join(args2, "");
        curr.Content = Text::Join(vars.Split(";"), NEWLINE);
        curr.Save(curr.Filename);
    }
}

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string ENABLED = PrefixVar("enabled");
const string NEW_FILENAME = PrefixVar("new_filename");

bool enabled;
string newFilename;

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(NEW_FILENAME, string());

    enabled = GetVariableBool(ENABLED);
    newFilename = GetVariableString(NEW_FILENAME);
}

const string NEWLINE = "\n";

const string CONFIG_FILENAME = "_";
const string CONFIG_DIRECTORY = ID + "\\";
const string CONFIG_PATH = CONFIG_DIRECTORY + CONFIG_FILENAME;

void LoadFiles()
{
    CommandList cfg(CONFIG_PATH);
    if (cfg is null)
    {
        CommandList().Save(CONFIG_PATH);
    }
    else
    {
        const array<string>@ const filenames = cfg.Content.Split(NEWLINE);
        const uint len = filenames.Length;

        for (uint i = 0; i < len; i++)
        {
            const string filename = filenames[i];
            if (!filename.IsEmpty())
            {
                presets.Add(CommandList(filename));
            }
        }
    }
}

void StoreFiles()
{
    CommandList cfg;
    for (uint i = 0; i < presets.Length; i++)
    {
        CommandList@ const preset = presets[i];
        const string filename = preset.Filename;

        preset.Save(filename);
        cfg.Content += filename + NEWLINE;
    }
    cfg.Save(CONFIG_PATH);
}

CommandList@ curr;
array<CommandList@> presets;

void Render()
{
    if (!(enabled && UI::Begin(NAME))) return;

    newFilename = UI::InputTextVar("New Config Name", NEW_FILENAME);
    if (UI::Button("Add New Config") && newFilename != CONFIG_FILENAME)
    {
        const string newPath = CONFIG_DIRECTORY + newFilename;
        CommandList().Save(newPath);
        presets.Add(CommandList(newPath));
        StoreFiles();
    }

    UI::Separator();

    if (UI::Button("Save"))
    {
        StoreFiles();
    }

    if (UI::BeginTabBar("Presets"))
    {
        for (uint i = 0; i < presets.Length; i++)
        {
            CommandList@ const preset = presets[i];
            const string path = preset.Filename;
            const uint start = path.FindLast(CONFIG_DIRECTORY) + CONFIG_DIRECTORY.Length;
            if (path.Length < start) continue;

            const string filename = path.Substr(start);
            if (UI::BeginTabItem(filename))
            {
                @curr = preset;
                OnSelectedPreset(preset);

                UI::EndTabItem();
            }
        }

        UI::EndTabBar();
    }

    UI::End();
}

void OnSelectedPreset(CommandList@ const preset)
{
    if (UI::Button("Load"))
    {
        preset.Process();
    }

    if (UI::BeginTable("Settings", 2))
    {
        array<string>@ const settings = preset.Content.Split(NEWLINE);
        UI::TableHeadersRow();
        if (UI::Button("New Setting"))
        {
            settings.Add(string());
        }

        const uint noIndex = ~0;
        uint idxAdd = noIndex;
        uint idxDel = noIndex;

        for (uint i = 0; i < settings.Length; i++)
        {
            UI::PushID("TableRow" + i);

            UI::TableNextColumn();
            settings[i] = UI::InputText("", settings[i]);

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
            settings.InsertAt(idxAdd, string());
        }
        else if (idxDel != noIndex)
        {
            settings.RemoveAt(idxDel);
        }

        preset.Content = Text::Join(settings, NEWLINE);

        UI::EndTable();
    }
}
