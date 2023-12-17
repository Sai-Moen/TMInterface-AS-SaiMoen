namespace smnu::UI::Combo
{
    // See full function
    shared bool Helper(
        const string &in label,
        const string &in currentMode,
        const dictionary@ const modes,
        const OnNewMode@ const onNewMode)
    {
        return Helper(label, currentMode, modes.GetKeys(), onNewMode);
    }

    // Draws a UI::Combo based on the given parameters
    // param label: label of the Combo
    // param currentMode: The current mode, should be in modes
    // param modes: All possible modes
    // param onNewMode: function that is called when the mode changes, and given the new mode name
    // returns: whether the combo is open
    shared bool Helper(
        const string &in label,
        const string &in currentMode,
        const array<string>@ const modes,
        const OnNewMode@ const onNewMode)
    {
        const bool open = UI::BeginCombo(label, currentMode);
        if (open)
        {
            for (uint i = 0; i < modes.Length; i++)
            {
                const string newMode = modes[i];
                if (UI::Selectable(newMode, currentMode == newMode))
                {
                    onNewMode(newMode);
                }
            }

            UI::EndCombo();
        }
        return open;
    }
}
