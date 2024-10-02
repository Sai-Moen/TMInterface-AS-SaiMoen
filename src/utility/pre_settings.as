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

const string PRESET_NAME = PREFIX + "preset_name";
const string PRESET_MAPPINGS = PREFIX + "preset_mappings";

string currPreset;
CommandList@ currCmdList;
array<string>@ presets;

void RegisterSettings()
{
    RegisterVariable(PRESET_NAME, "");
    RegisterVariable(PRESET_MAPPINGS, "");

    currPreset = GetVariableString(PRESET_NAME);
    const string presetMappings = GetVariableString(PRESET_MAPPINGS);
    if (presetMappings == "")
    {
        @presets = array<string>();
        ClearPresetName();
    }
    else
    {
        @presets = presetMappings.Split(MAPPING_SEP);
        if (presets.Find(currPreset) == -1)
            ClearPresetName();
        else
            LoadCurrentPreset();
    }
}

void ClearPresetName()
{
    SetVariable(PRESET_NAME, currPreset = "");
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
            for (uint i = 0; i < presets.Length; i++)
            {
                const string preset = presets[i];

                const bool isCurrentPreset = currPreset == preset;
                if (UI::Selectable(preset, isCurrentPreset))
                {
                    if (isCurrentPreset)
                    {
                        currPreset = "";
                        editedActivePreset = "";
                        @currCmdList = null;
                    }
                    else
                    {
                        currPreset = preset;
                        LoadCurrentPreset();
                    }
                    SetVariable(PRESET_NAME, currPreset);
                }
            }

            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Edit Active Preset"))
        {
            if (currCmdList !is null)
            {
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
                            value = '"' + GetVariableString(name) + '"';
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
                    SavePreset(currPreset, currCmdList);
                    currCmdList.Process();
                }

                if (UI::InputTextMultiline("##EditActivePreset Multiline", editedActivePreset, MULTILINE_AUTOFILL))
                    currCmdList.Content = editedActivePreset;
            }

            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Create New Preset"))
        {
            newPresetName = UI::InputText("New Preset Name", newPresetName);
            const bool invalidCharacter = newPresetName.FindFirst(MAPPING_SEP) != -1;
            if (invalidCharacter)
                UI::Text("Please do not include the following string in the name: \"" + MAPPING_SEP + "\"");

            UI::BeginDisabled(invalidCharacter);
            if (UI::Button("Create Preset"))
            {
                SavePreset(newPresetName);
                presets.Add(newPresetName);
                SetVariable(PRESET_MAPPINGS, Text::Join(presets, MAPPING_SEP));
                newPresetName = "";
            }
            UI::EndDisabled();

            UI::EndTabItem();
        }

        UI::EndTabBar();
    }
}

void LoadCurrentPreset()
{
    CommandList cmdlist(DIRECTORY + currPreset);
    if (cmdlist is null)
    {
        log("Cannot load preset, file not found!", Severity::Error);
        return;
    }

    cmdlist.Process();
    editedActivePreset = cmdlist.Content;
    @currCmdList = cmdlist;
}

void SavePreset(const string &in preset, CommandList@ cmdlist = CommandList())
{
    cmdlist.Save(DIRECTORY + preset);
}
