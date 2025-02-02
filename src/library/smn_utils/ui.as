// smn_utils - v2.1.0a

/*

User Interface
- Widget helpers

*/


// puts a (i) on the same line and returns whether it is being hovered
void TooltipOnHover(const string &in text)
{
    UI::SameLine();
    UI::TextDimmed("(i)");
    if (UI::IsItemHovered() && UI::BeginTooltip())
    {
        UI::Text(text);
        UI::EndTooltip();
    }
}

// combo w/ index
funcdef void OnNewModeIndex(const uint newIndex);

bool ComboHelper(const string &in label, const array<string>@ names, const uint currentIndex, OnNewModeIndex@ onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, names[currentIndex]);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = names[i];
            if (UI::Selectable(name, i == currentIndex))
                onNewMode(i);
        }

        UI::EndCombo();
    }
    return isOpen;
}

// combo w/ string
funcdef void OnNewModeName(const string &in newName);

bool ComboHelper(const string &in label, const array<string>@ names, const string &in currentName, OnNewModeName@ onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, currentName);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = names[i];
            if (UI::Selectable(name, name == currentName))
                onNewMode(name);
        }

        UI::EndCombo();
    }
    return isOpen;
}
