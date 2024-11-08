// User Interface

namespace utils
{


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

// combo w/ index
funcdef void OnNewModeIndex(const uint newIndex);

bool ComboHelper(
    const string &in label,
    const uint currentMode,
    const array<string>@ const allModes,
    const OnNewModeIndex@ const onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, allModes[currentMode]);
    if (isOpen)
    {
        const uint len = allModes.Length;
        for (uint i = 0; i < len; i++)
        {
            const string newMode = allModes[i];
            if (UI::Selectable(newMode, i == currentMode))
                onNewMode(i);
        }

        UI::EndCombo();
    }
    return isOpen;
}

// combo w/ string
funcdef void OnNewModeName(const string &in newMode);

bool ComboHelper(
    const string &in label,
    const string &in currentMode,
    const array<string>@ const allModes,
    const OnNewModeName@ const onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, currentMode);
    if (isOpen)
    {
        const uint len = allModes.Length;
        for (uint i = 0; i < len; i++)
        {
            const string newMode = allModes[i];
            if (UI::Selectable(newMode, newMode == currentMode))
                onNewMode(newMode);
        }

        UI::EndCombo();
    }
    return isOpen;
}


} // namespace utils
