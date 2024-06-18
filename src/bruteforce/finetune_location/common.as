// common/utils

string PreciseFormat(const double value)
{
    return Text::FormatFloat(value, " ", 0, 16);
}

funcdef void OnNewMode(const string &in);

bool ComboHelper(
    const string &in label,
    const string &in currentMode,
    const array<string>@ const allModes,
    const OnNewMode@ const onNewMode)
{
    const bool isOpen = UI::BeginCombo(label, currentMode);
    if (isOpen)
    {
        for (uint i = 0; i < allModes.Length; i++)
        {
            const string newMode = allModes[i];
            if (UI::Selectable(newMode, currentMode == newMode))
            {
                onNewMode(newMode);
            }
        }

        UI::EndCombo();
    }
    return isOpen;
}

void CapMax(const string &in variableName, const int tfrom, const int tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}
