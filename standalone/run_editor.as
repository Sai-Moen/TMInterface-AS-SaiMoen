// Text editor plugin for TMInterface!

const string ID      = "repp";
const string NAME    = "RunEditor++";
const string COMMAND = "repp";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = NAME;
    info.Version = "v2.0.1.2";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(COMMAND, "Toggles " + NAME + " window", OnCommand);
}

void OnDisabled()
{
    TrySaveAll();
}

const string NEWLINE  = "\n";

const string CONFIG_FILENAME = ID;
const string CONFIG_DIRECTORY = ID + "\\";
const string CONFIG_PATH = CONFIG_DIRECTORY + CONFIG_FILENAME;

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string ENABLED = PrefixVar("enabled");
const string CURR_NAME = PrefixVar("curr_name");

bool enabled;

string currName;
Script@ curr;
dictionary files;

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(CURR_NAME, string());

    enabled = GetVariableBool(ENABLED);

    LoadFiles();
    currName = GetVariableString(CURR_NAME);
    @curr = GetFile(currName);
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
        const auto@ const filenames = cfg.Content.Split(NEWLINE);
        for (uint i = 0; i < filenames.Length; i++)
        {
            const string s = filenames[i];
            if (!s.IsEmpty())
            {
                TryOpenFile(s);
            }
        }
    }
}

void StoreFiles()
{
    CommandList cfg;

    const array<string>@ const keys = files.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        Script@ const file = GetFile(key);
        if (file is null)
        {
            files.Delete(key);
            continue;
        }

        file.Save();
        cfg.Content += file.RelativeName() + NEWLINE;
    }

    cfg.Save(CONFIG_PATH);
}

void CreateFile(const string &in filename)
{
    CommandList().Save(filename);
}

const string HELP = "help";
const string TOGGLE = "toggle";
const string SAVE = "save";
const string LOAD = "load";

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
    else if (cmd == SAVE)
    {
        TrySaveFile();
    }
    else if (cmd == LOAD)
    {
        TryLoadFile();
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
    log(SAVE + "   - save the currently selected file");
    log(LOAD + "   - load the currently selected file");
}

const string SCRIPT_DIR  = "\\TMInterface\\Scripts\\";

CommandList@ currCommands;
CommandList@ CurrCommands
{
    get { return currCommands; }
    set
    {
        @currCommands = value;
        currCommands.Process(CommandListProcessOption::ExecuteImmediately);
        SetCurrentCommandList(currCommands);
    }
}

void UpdateCurrCommands(CommandList@ const file)
{
    UpdateCurrCommands(file, file);
}

void UpdateCurrCommands(CommandList@ const file, CommandList@ const value)
{
    if (file is CurrCommands)
    {
        @CurrCommands = value;
    }
}

class Script
{
    CommandList@ file;
    CommandList@ File
    {
        get const { return file; }
        set
        {
            UpdateCurrCommands(file, value);
            @file = value;
        }
    }

    string Filename { get { return File.Filename; } }

    bool fileChanged;
    string Content
    {
        get { return File.Content; }
        set
        {
            File.Content = value;
            fileChanged = true;
        }
    }

    Script(const string &in scriptRelativePath)
    {
        Open(scriptRelativePath);
    }

    void Open()
    {
        Open(Filename);
    }

    void Open(const string &in scriptRelativePath)
    {
        @File = CommandList(scriptRelativePath);
        fileChanged = false;
    }

    void Save()
    {
        File.Save(Filename);
        fileChanged = false;
        UpdateCurrCommands(File);
    }

    void Load()
    {
        Save();
        @CurrCommands = File;
    }

    string Edited() const
    {
        return fileChanged ? "*" : " ";
    }

    string RelativeName()
    {
        const string scriptname = Filename;
        return scriptname.Substr(scriptname.FindLast(SCRIPT_DIR) + SCRIPT_DIR.Length);
    }
}

Script@ GetFile(const string &in key)
{
    return cast<Script@>(files[key]);
}

void TryOpenFile(const string &in filename)
{
    Script@ const file = Script(filename);
    if (file is null)
    {
        log("Could not find file " + filename, Severity::Error);
        DiscardFile(filename);
        return;
    }

    const string key = file.RelativeName();
    @files[key] = file;
    StoreFiles();

    currName = key;
    @curr = file;
}

void TryCloseFile()
{
    DiscardFile(curr.RelativeName());
    @curr = null;
    currName = string();
}

void TrySaveFile()
{
    if (curr !is null)
    {
        curr.Save();
    }
}

void TrySaveFile(const string &in key)
{
    Script@ const file = GetFile(key);
    if (file is null)
    {
        DiscardFile(key);
        return;
    }

    file.Save();
}

void TrySaveAll()
{
    const array<string>@ const keys = files.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        TrySaveFile(keys[i]);
    }
}

void TryLoadFile()
{
    if (curr !is null)
    {
        curr.Load();
    }
}

void DiscardFile(const string &in key)
{
    files.Delete(key);
    StoreFiles();
}

const string MULTILINE_LABEL = string();
const vec2 MULTILINE_SIZE = vec2(-1);

string newFilename;

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
    newFilename = UI::InputText("Enter filename", newFilename);
    if (UI::Button("Open"))
    {
        TryOpenFile(newFilename);
        newFilename = string();
    }

    UI::Separator();

    if (UI::Button("Save All"))
    {
        TrySaveAll();
    }

    if (UI::BeginTabBar("Files"))
    {
        const array<string>@ const keys = files.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            if (key.IsEmpty())
            {
                DiscardFile(key);
                continue;
            }

            Script@ const file = GetFile(key);
            if (file is null) continue;

            if (UI::BeginTabItem(key))
            {
                UI::TextWrapped(file.Edited());

                currName = key;
                @curr = file;
                OnSelectedFile();

                UI::EndTabItem();
            }
        }

        UI::EndTabBar();
    }
}

void OnSelectedFile()
{
    if (UI::Button("Save"))
    {
        TrySaveFile();
        return;
    }
    UI::SameLine();
    if (UI::Button("Load"))
    {
        curr.Load();
    }
    UI::SameLine();
    if (UI::Button("Refresh"))
    {
        curr.Open();
        return;
    }
    UI::SameLine();
    if (UI::Button("Close"))
    {
        TryCloseFile();
        return;
    }

    string text = curr.Content;
    if (UI::InputTextMultiline(MULTILINE_LABEL, text, MULTILINE_SIZE))
    {
        curr.Content = text;
    }
}
