// Common elements

const string NEWLINE = "\n";

bool IsFree(const string &in filename)
{
    return filename != editor::ID && filename != presettings::ID;
}

const string CONFIG_DIRECTORY = ID + "\\";

const string RelativeName(const string &in filename)
{
    return filename.Substr(filename.FindLast(CONFIG_DIRECTORY) + CONFIG_DIRECTORY.Length);
}

void CreateFile(const string &in filename)
{
    CommandList().Save(filename);
}

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

const string SCRIPT_DIR  = "\\TMInterface\\Scripts\\";

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

    Script(const string &in scriptRelativePath, bool &out valid)
    {
        valid = Open(scriptRelativePath);
    }

    bool Open()
    {
        return Open(Filename);
    }

    bool Open(const string &in scriptRelativePath)
    {
        CommandList script(scriptRelativePath);
        if (script is null) return false;

        @File = script;
        fileChanged = false;
        return true;
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
        return Filename.Substr(Filename.FindLast(SCRIPT_DIR) + SCRIPT_DIR.Length);
    }
}

funcdef void Draw();

void TabItemHelper(const string &in label, Draw@ const draw)
{
    if (UI::BeginTabItem(label))
    {
        draw();
        UI::EndTabItem();
    }
}
