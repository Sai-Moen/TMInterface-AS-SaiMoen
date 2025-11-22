/*

smn_utils | User Interface | v3.0.0

Features:
- Widget helpers

*/


void TooltipOnHover(const string &in text)
{
    if (UI::IsItemHovered())
    {
        if (UI::BeginTooltip())
        {
            UI::Text(text);
            UI::EndTooltip();
        }
    }
}

// combo w/ index
funcdef void OnSelectIndex(const uint index);

bool ComboHelper(const string &in label, const array<string>@ names, const uint currentIndex, OnSelectIndex@ onSelect)
{
    const bool isOpen = UI::BeginCombo(label, names[currentIndex]);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = names[i];
            if (UI::Selectable(name, i == currentIndex))
                onSelect(i);
        }

        UI::EndCombo();
    }
    return isOpen;
}

// combo w/ string
funcdef void OnSelectName(const string &in name);

bool ComboHelper(const string &in label, const array<string>@ names, const string &in currentName, OnSelectName@ onSelect)
{
    const bool isOpen = UI::BeginCombo(label, currentName);
    if (isOpen)
    {
        const uint len = names.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = names[i];
            if (UI::Selectable(name, name == currentName))
                onSelect(name);
        }

        UI::EndCombo();
    }
    return isOpen;
}
