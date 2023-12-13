namespace presettings
{
    const string ID = "presettings";
    const string PREFIX = ::PREFIX + ID + "_";
    const string NAME = "PreSettings";

    const string CONFIG_PATH = CONFIG_DIRECTORY + ID;

    void OnDisabled()
    {
        StoreFiles();
    }

    const string CURR_NAME = PREFIX + "curr_name";

    string currName;
    string CurrName
    {
        get { return currName; }
        set { SetVariable(CURR_NAME, currName = value); }
    }

    CommandList@ curr;
    dictionary presets;

    void OnRegister()
    {
        RegisterVariable(CURR_NAME, string());

        LoadFiles();
        currName = GetVariableString(CURR_NAME);
        @curr = GetPreset(currName);
    }

    bool changed;

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

    string newFilename;

    void Draw()
    {
        newFilename = UI::InputText("New Config Name", newFilename);
        if (UI::Button("Add New Config") && IsFree(newFilename))
        {
            const string newPath = CONFIG_DIRECTORY + newFilename;
            CreateFile(newPath);

            CommandList@ const script = CommandList(newPath);
            @presets[newFilename] = script;
            StoreFiles();

            CurrName = newFilename;
            @curr = script;
            newFilename = string();
        }

        UI::Separator();

        if (UI::Button("Save"))
        {
            StoreFiles();
        }

        if (UI::BeginCombo("Presets", CurrName))
        {
            const array<string>@ const keys = presets.GetKeys();
            for (uint i = 0; i < keys.Length; i++)
            {
                const string key = keys[i];
                CommandList@ const preset = GetPreset(key);
                if (UI::Selectable(key, preset is curr))
                {
                    CurrName = key;
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
                presets.Delete(CurrName);
                StoreFiles();

                CurrName = string();
                @curr = null;
            }
            else
            {
                curr.Content = Text::Join(settings, NEWLINE);
            }

            UI::EndTable();
        }
    }
}
