typedef int ms;

string PreciseFormat(const double value)
{
    return Text::FormatFloat(value, " ", 0, 16);
}

// combo w/ index
funcdef void OnSelectIndex(const uint newIndex);

bool ComboHelper(
    const string &in label,
    const uint current,
    const array<string>@ const all,
    const OnSelectIndex@ const onSelect)
{
    const bool isOpen = UI::BeginCombo(label, all[current]);
    if (isOpen)
    {
        const uint len = all.Length;
        for (uint i = 0; i < len; i++)
        {
            const string name = all[i];
            if (UI::Selectable(name, i == current))
                onSelect(i);
        }

        UI::EndCombo();
    }
    return isOpen;
}
