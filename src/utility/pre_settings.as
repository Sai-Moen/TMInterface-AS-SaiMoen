// Preset Settings

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = "PreSettings";
    info.Description = "Preset Settings";
    info.Version = "v2.1.1a";
    return info;
}

void Main()
{
    RegisterSettings();
    RegisterSettingsPage("PreSettings", Window);
}

const string MAPPING_SEP = "/";
const string DIRECTORY = "presets/";

const string PREFIX = "presettings_";

const string VAR_PRESET_NAME     = PREFIX + "preset_name";
const string VAR_PRESET_MAPPINGS = PREFIX + "preset_mappings";

string currPreset;
string CurrPreset { set { SetVariable(VAR_PRESET_NAME, currPreset = value); } }

CommandList@ currCmdList;
array<string>@ presets;

void RegisterSettings()
{
    RegisterVariable(VAR_PRESET_NAME, "");
    RegisterVariable(VAR_PRESET_MAPPINGS, "");

    currPreset = GetVariableString(VAR_PRESET_NAME);
    const string presetMappings = GetVariableString(VAR_PRESET_MAPPINGS);
    if (presetMappings == "")
    {
        @presets = array<string>();
        CurrPreset = "";
    }
    else
    {
        @presets = presetMappings.Split(MAPPING_SEP);
        if (presets.Find(currPreset) == -1)
            CurrPreset = "";
        else
            LoadPreset();
    }
}

const vec2 MULTILINE_AUTOFILL = vec2(-1, -1);

string editedActivePreset;
string newPresetName;

void Window()
{
    if (UI::BeginTabBar("PreSettings TabBar"))
    {
        if (UI::BeginTabItem("Presets"))
        {
            TabItemPresets();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Edit Active Preset"))
        {
            TabItemEditActivePreset();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Create New Preset"))
        {
            TabItemCreateNewPreset();
            UI::EndTabItem();
        }

        UI::EndTabBar();
    }
}

void TabItemPresets()
{
    for (uint i = 0; i < presets.Length; i++)
    {
        const string preset = presets[i];

        const bool isCurrentPreset = currPreset == preset;
        if (UI::Selectable(preset, isCurrentPreset))
        {
            if (isCurrentPreset)
                ClearCurrentPreset();
            else
                LoadPreset(preset);
        }
    }
}

void TabItemEditActivePreset()
{
    if (currCmdList is null)
        return;

    UI::Text(currPreset);

    if (UI::Button("Remove Preset"))
    {
        presets.RemoveAt(presets.Find(currPreset));
        SavePresets();
        ClearCurrentPreset();
        return;
    }

    if (UI::Button("Add All Missing ConVars"))
    {
        const auto@ const convars = ListVariables();
        for (uint i = 0; i < convars.Length; i++)
        {
            const auto convar = convars[i];

            // holy O(n^2)
            const string name = convar.Name;
            if (currCmdList.Content.FindFirst(name) != -1)
                continue;

            string value;
            switch (convar.Type)
            {
            case VariableType::Double:
                value = GetVariableDouble(name);
                break;
            case VariableType::String:
                value = "\"" + GetVariableString(name) + "\"";
                break;
            case VariableType::Boolean:
                value = GetVariableBool(name);
                break;
            }

            // holy O(n^2)
            currCmdList.Content += "\nset " + name + " " + value;
        }
        editedActivePreset = currCmdList.Content;
    }

    if (UI::Button("Save/Load Changes"))
    {
        SavePresetFile(currPreset, currCmdList);
        currCmdList.Process();
    }

    if (UI::InputTextMultiline("##EditActivePreset Multiline", editedActivePreset, MULTILINE_AUTOFILL))
        currCmdList.Content = editedActivePreset;
}

void TabItemCreateNewPreset()
{
    newPresetName = UI::InputText("New Preset Name", newPresetName);
    const bool invalidCharacter = newPresetName.FindFirst(MAPPING_SEP) != -1;
    if (invalidCharacter)
        UI::Text("Please do not include the following string in the name: \"" + MAPPING_SEP + "\"");

    UI::BeginDisabled(invalidCharacter);
    if (UI::Button("Create Preset"))
    {
        SavePresetFile(newPresetName);
        presets.Add(newPresetName);
        SavePresets();
        newPresetName = "";
    }

    if (UI::Button("Try Recover Accidentally Removed Preset"))
    {
        const auto@ const cmdlist = TryLoadPresetFile(newPresetName);
        if (cmdlist is null)
        {
            log("Cannot recover preset, file not found!", Severity::Error);
        }
        else
        {
            presets.Add(newPresetName);
            SavePresets();
            newPresetName = "";
        }
    }
    UI::EndDisabled();
}

void LoadPreset(const string &in preset = currPreset)
{
    const auto@ const cmdlist = TryLoadPresetFile(preset);
    if (cmdlist is null)
    {
        log("Cannot load preset, file not found!", Severity::Error);
        return;
    }

    @currCmdList = cmdlist;
    currCmdList.Process();
    CurrPreset = preset;
    editedActivePreset = currCmdList.Content;
}

CommandList@ TryLoadPresetFile(const string &in preset)
{
    // this is the only way to check if a file exists without crashing
    CommandList cmdlist(DIRECTORY + preset);
    return cmdlist;
}

void SavePresetFile(const string &in preset, CommandList@ cmdlist = CommandList())
{
    cmdlist.Save(DIRECTORY + preset);
}

void ClearCurrentPreset()
{
    CurrPreset = "";
    editedActivePreset = "";
    @currCmdList = null;
}

void SavePresets()
{
    SetVariable(VAR_PRESET_MAPPINGS, Text::Join(presets, MAPPING_SEP));
}
