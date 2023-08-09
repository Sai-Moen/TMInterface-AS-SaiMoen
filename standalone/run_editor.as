// Text editor plugin for TMInterface!

const string NAME    = "RunEditor++";
const string COMMAND = "toggle_repp";

const string NEWLINE  = "\n";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = NAME;
    info.Description = "Use " + COMMAND + " to open a text editor in-game";
    info.Version = "v2.0.0.0";
    return info;
}

void Main()
{
    RegisterCustomCommand(COMMAND, "Toggles " + NAME + " window", OnCommand);
}

bool isEnabled = false;

void OnCommand(
    int fromTime,
    int toTime,
    const string&in commandLine,
    const array<string>&in args)
{
    isEnabled = !isEnabled;
}

string filename;
array<CommandList> files;

void Render()
{
    if (!(isEnabled && UI::Begin(NAME)))
    {
        return;
    }

    UI::TextWrapped("To create a new line below the current one, press the button on that line.");

    filename = UI::InputText("Enter filename", filename);
    if (UI::Button("Open"))
    {
        CommandList file(filename);
        if (file is null)
        {
            log("Could not find file!", Severity::Error);
        }
        else
        {
            files.Add(file);
        }
    }
    UI::SameLine();
    const bool closeFile = UI::Button("Close");

    if (UI::BeginTabBar("Files"))
    {
        uint closeIndex = Math::UINT_MAX;
        for (uint i = 0; i < files.Length; i++)
        {
            if (OnFile(files[i], closeFile))
            {
                closeIndex = i;
            }
        }

        if (closeIndex != Math::UINT_MAX)
        {
            files.RemoveAt(closeIndex);
        }

        UI::EndTabBar();
    }

    UI::End();
}

bool OnFile(CommandList@ const file, const bool closeFile)
{
    if (!UI::BeginTabItem(file.Filename))
    {
        return false;
    }

    const array<string>@ const lines = file.Content.Split(NEWLINE);
    array<string> content(lines.Length);
    for (uint i = 0; i < lines.Length; i++)
    {
        string line = UI::InputText("" + i, lines[i]);

        UI::PushID("Button" + i);

        UI::SameLine();
        if (UI::Button("Add"))
        {
            const uint64 time = Text::ParseUInt(line.Split(" ")[0]) + 10;
            line += NEWLINE + time;
        }

        UI::PopID();

        content[i] = line;
    }
    file.Content = Text::Join(content, NEWLINE);

    if (UI::Button("Save"))
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

    UI::EndTabItem();
    return closeFile;
}
