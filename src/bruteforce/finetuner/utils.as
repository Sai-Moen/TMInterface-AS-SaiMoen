typedef int32 ms;

string PreciseFormat(const double value, const uint precision = 12)
{
    return Text::FormatFloat(value, " ", 0, precision);
}

string PreciseFormat(const vec3 &in value, const uint precision = 12)
{
    return
        PreciseFormat(value.x, precision) + " " +
        PreciseFormat(value.y, precision) + " " +
        PreciseFormat(value.z, precision);
}

string RightPad(string &in s, const uint padTo)
{
    const uint len = s.Length;
    if (len < padTo)
    {
        s.Resize(padTo);
        for (uint i = len; i < padTo; i++)
            s[i] = ' ';
    }
    return s;
}

string Repeat(const uint8 char, const uint times)
{
    string builder;
    builder.Resize(times);
    for (uint i = 0; i < times; i++)
        builder[i] = char;
    return builder;
}

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
