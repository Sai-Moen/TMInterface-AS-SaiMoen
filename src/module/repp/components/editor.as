namespace editor
{
    const string ID = "editor";
    const string PREFIX = ::PREFIX + ID + "_";
    const string NAME = "Editor";

    const string CONFIG_PATH = CONFIG_DIRECTORY + ID;

    void OnDisabled()
    {
        TrySaveAll();
    }

    const string CURR_NAME = PREFIX + "curr_name";

    string currName;
    string CurrName
    {
        get { return currName; }
        set { SetVariable(CURR_NAME, currName = value); }
    }

    Script@ curr;
    dictionary files;

    void OnRegister()
    {
        RegisterVariable(CURR_NAME, string());

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

    // Commands
    const string HELP = "help";
    const string SAVE = "save";
    const string LOAD = "load";

    void OnCommand(const array<string> &in args)
    {
        if (args.Length < 2)
        {
            LogHelp();
            return;
        }

        const string cmd = args[1];
        if (cmd == HELP)
        {
            LogHelp();
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
        log(HELP + " - log this message");
        log(SAVE + " - save the currently selected file");
        log(LOAD + " - load the currently selected file");
    }

    Script@ GetFile(const string &in key)
    {
        return cast<Script@>(files[key]);
    }

    void TryOpenFile(const string &in filename)
    {
        bool valid;
        Script@ const file = Script(filename, valid);
        if (!valid)
        {
            log("Could not find file " + filename, Severity::Error);
            DiscardFile(filename);
            return;
        }

        const string key = file.RelativeName();
        @files[key] = file;
        StoreFiles();

        CurrName = key;
        @curr = file;
    }

    void TryCloseFile()
    {
        DiscardFile(curr.RelativeName());
        @curr = null;
        CurrName = string();
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

    // UI
    const string MULTILINE_LABEL = "";
    const vec2 MULTILINE_SIZE = vec2(-1);

    string newFilename;

    void Draw()
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

        if (UI::BeginCombo("Files", CurrName))
        {
            const array<string>@ const keys = files.GetKeys();
            for (uint i = 0; i < keys.Length; i++)
            {
                const string key = keys[i];
                Script@ const file = GetFile(key);
                if (UI::Selectable(key, file is curr))
                {
                    CurrName = key;
                    @curr = file;
                }

                if (file is null) continue;

                UI::SameLine();
                UI::TextWrapped(file.Edited());
            }

            UI::EndCombo();
        }

        if (curr !is null)
        {
            DrawCurrent();
        }
    }

    void DrawCurrent()
    {
        UI::TextWrapped(curr.Edited());
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
}
