// Preset Settings

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = "PreSettings";
    info.Description = "Preset Settings";
    info.Version = "v2.1.1b";
    return info;
}

void Main()
{
    RegisterSettings();
    RegisterCustomCommand("include", "Include script in another script", OnInclude);
    RegisterSettingsPage("PreSettings", Window);
}

const string MAPPING_SEP = "/";
const string DIRECTORY = "presets/";

const string VAR = "presettings_";

const string VAR_PRESET_NAME     = VAR + "preset_name";
const string VAR_PRESET_MAPPINGS = VAR + "preset_mappings";

const string VAR_FILTER = VAR + "filter";

string currPreset;
string CurrPreset { set { SetVariable(VAR_PRESET_NAME, currPreset = value); } }

CommandList@ currCmdList;
array<string>@ presets;

string filter;

void RegisterSettings()
{
    RegisterVariable(VAR_PRESET_NAME, "");
    RegisterVariable(VAR_PRESET_MAPPINGS, "");
    RegisterVariable(VAR_FILTER, "");

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
    
    filter = GetVariableString(VAR_FILTER);
}

void OnInclude(int, int, const string &in, const array<string> &in args)
{
    if (args.IsEmpty())
    {
        log("[include] no args given", Severity::Warning);
        return;
    }

    const string path = args[0];
    CommandList cmdlist(path);
    if (cmdlist is null)
    {
        log("[include] file '" + path + "' does not exist!", Severity::Error);
        return;
    }

    cmdlist.Process(CommandListProcessOption::ExecuteImmediately);
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

    filter = UI::InputTextVar("ConVar filter", VAR_FILTER);
    TooltipOnHover("Filter", "Only adds vars that start with this (empty to not filter).");

    if (UI::Button("Add All Missing ConVars"))
    {
        const auto@ const convars = ListVariables();
        for (uint i = 0; i < convars.Length; i++)
        {
            const auto convar = convars[i];

            // holy O(n^2)
            const string name = convar.Name;
            if (name.FindFirst(filter) != 0 || currCmdList.Content.FindFirst(name) != -1)
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

// puts a (i) on the same line and returns whether it is being hovered
void TooltipOnHover(const string &in label, const string &in text)
{
    UI::SameLine();
    UI::PushID(label);
    UI::TextDimmed("(i)");
    UI::PopID();
    if (UI::IsItemHovered() && UI::BeginTooltip())
    {
        UI::Text(text);
        UI::EndTooltip();
    }
}
