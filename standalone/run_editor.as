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
    info.Version = "v2.0.1.0";
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

string GetScriptName(CommandList@ const file)
{
    string scriptname = file.Filename;
    scriptname.Erase(0, scriptname.FindLast(SCRIPT_DIR) + SCRIPT_DIR_LEN);
    return scriptname;
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
array<CommandList> files;

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
    CommandList file(filename);
    if (file is null)
    {
        log("Could not find file '" + filename + "'!", Severity::Error);
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

void SetOpenFiles()
{
    string openFiles;
    for (uint i = 0; i < files.Length; i++)
    {
        openFiles += GetScriptName(files[i]) + FILE_SEP;
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

    if (UI::BeginTabBar("Files"))
    {
        uint closeIndex = Math::UINT_MAX;
        for (uint i = 0; i < files.Length; i++)
        {
            CommandList@ const file = files[i];
            if (UI::BeginTabItem(GetScriptName(file)))
            {
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

void OnSelectedFile(CommandList@ const file, const bool fileSave, const bool fileRefresh)
{
    if (fileSave)
    {
        if (file.Save(file.Filename))
        {
            log("Saved!", Severity::Success);
        }
        else
        {
            log("Could not save!", Severity::Error);
        }
    }
    else if (fileRefresh)
    {
        file = CommandList(file.Filename);
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
