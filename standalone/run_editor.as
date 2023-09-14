// Text editor plugin for TMInterface!

const string ID      = "repp";
const string NAME    = "RunEditor++";
const string COMMAND = "toggle_repp";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = "Use " + COMMAND + " to open a text editor in-game";
    info.Version = "v2.0.1.1";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(COMMAND, "Toggles " + NAME + " window", OnCommand);
}

const string NEWLINE  = "\n";
const string FILE_SEP = "|";

const string SCRIPT_DIR  = "\\TMInterface\\Scripts\\";
const int SCRIPT_DIR_LEN = SCRIPT_DIR.Length;

class Script
{
    CommandList file;
    string Filename { get { return file.Filename; } }

    bool fileChanged;
    string Content
    {
        get { return file.Content; }
        set
        {
            file.Content = value;
            fileChanged = true;
        }
    }

    Script(const string &in scriptRelativePath)
    {
        Open(scriptRelativePath);
    }

    void Open(const string &in scriptRelativePath)
    {
        fileChanged = false;
        file = CommandList(scriptRelativePath);
    }

    bool Save(const string &in scriptRelativePath)
    {
        fileChanged = false;
        return file.Save(scriptRelativePath);
    }

    string Edited()
    {
        return fileChanged ? "*" : "";
    }

    string GetScriptName()
    {
        const string scriptname = file.Filename;
        return scriptname.Substr(scriptname.FindLast(SCRIPT_DIR) + SCRIPT_DIR_LEN);
    }
}

const string PrefixVar(const string &in var)
{
    return ID + "_" + var;
}

const string ENABLED = PrefixVar("enabled");
const string OPEN_FILES = PrefixVar("open_files");

const string WIDTH  = PrefixVar("width");
const string HEIGHT = PrefixVar("height");

bool enabled;

string filename;
array<Script@> files;

vec2 size;

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(OPEN_FILES, "");

    RegisterVariable(WIDTH, 0x200);
    RegisterVariable(HEIGHT, 0x200);

    enabled = GetVariableBool(ENABLED);

    const auto@ const filenames = GetVariableString(OPEN_FILES).Split(FILE_SEP);
    for (uint i = 0; i < filenames.Length; i++)
    {
        const string s = filenames[i];
        if (s != "")
        {
            TryOpenFile(s);
        }
    }

    const float width  = GetVariableDouble(WIDTH);
    const float height = GetVariableDouble(HEIGHT);
    size = vec2(width, height);
}

void OnCommand(
    int fromTime,
    int toTime,
    const string &in commandLine,
    const array<string> &in args)
{
    enabled = !enabled;
    SetVariable(ENABLED, enabled);
}

void TryOpenFile(const string &in filename)
{
    Script@ const file = Script(filename);
    if (file is null)
    {
        log("Could not find file " + filename, Severity::Error);
        return;
    }

    files.Add(file);
    SetOpenFiles();
}

void TryCloseFile(const uint index)
{
    if (index >= files.Length)
    {
        log("Could not close file: invalid index -> " + index, Severity::Error);
        return;
    }

    files.RemoveAt(index);
    SetOpenFiles();
}

void TrySaveFile(Script@ const file)
{
    const string filename = file.Filename;
    if (file.Save(filename)) return;
    
    log("Could not save " + filename, Severity::Error);
}

void SetOpenFiles()
{
    string openFiles;
    for (uint i = 0; i < files.Length; i++)
    {
        openFiles += files[i].GetScriptName() + FILE_SEP;
    }
    SetVariable(OPEN_FILES, openFiles);
}

void Render()
{
    if (!(enabled && UI::Begin(NAME))) return;

    filename = UI::InputText("Enter filename", filename);
    if (UI::Button("Open"))
    {
        TryOpenFile(filename);
    }

    const float width = UI::InputFloatVar("Width", WIDTH);
    const float height = UI::InputFloatVar("Height", HEIGHT);
    size = vec2(width, height);

    UI::Separator();

    const bool fileClose = UI::Button("Close");
    UI::SameLine();
    const bool fileRefresh = UI::Button("Refresh");
    UI::SameLine();
    const bool fileSave = UI::Button("Save");
    UI::SameLine();
    if (UI::Button("Save All"))
    {
        for (uint i = 0; i < files.Length; i++)
        {
            TrySaveFile(files[i]);
        }
    }

    if (UI::BeginTabBar("Files"))
    {
        uint closeIndex = Math::UINT_MAX;
        for (uint i = 0; i < files.Length; i++)
        {
            Script@ const file = files[i];
            if (UI::BeginTabItem(file.GetScriptName()))
            {
                UI::TextWrapped(file.Edited());
                OnSelectedFile(file, fileSave, fileRefresh);
                OnCloseCheck(closeIndex, i, fileClose);
                UI::EndTabItem();
            }
        }

        if (closeIndex != Math::UINT_MAX)
        {
            TryCloseFile(closeIndex);
        }

        UI::EndTabBar();
    }

    UI::End();
}

void OnSelectedFile(Script@ const file, const bool fileSave, const bool fileRefresh)
{
    if (fileSave)
    {
        TrySaveFile(file);
    }
    else if (fileRefresh)
    {
        file.Open(file.Filename);
    }

    string text = file.Content;
    if (UI::InputTextMultiline("", text, size))
    {
        file.Content = text;
    }
}

void OnCloseCheck(uint& closeIndex, const uint index, const bool fileClose)
{
    if (fileClose)
    {
        closeIndex = index;
    }
}
