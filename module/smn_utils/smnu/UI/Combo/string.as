namespace smnu::UI::Combo
{
    /**
    * Draws a UI::Combo based on the given {string}s.
    * @param label: label of the Combo
    * @param currentMode: name of the current mode, should be in |modes|
    * @param modes: All possible modes
    * @param onNewMode: function that is called when the mode changes, and given the new mode name
    * @ret: the return value of UI::EndCombo, or false if no combo
    */
    shared bool Strings(
        const string &in label,
        const string &in currentMode,
        const array<string>@ const modes,
        OnNewModeName@ const onNewMode)
    {
        if (UI::BeginCombo(label, currentMode))
        {
            for (uint i = 0; i < modes.Length; i++)
            {
                const string newMode = modes[i];
                if (UI::Selectable(newMode, currentMode == newMode))
                {
                    onNewMode(newMode);
                }
            }

            return UI::EndCombo();
        }

        return false;
    }

    /**
    * Draws a UI::Combo based on the given {dictionary}.
    * @param label: label of the Combo
    * @param currentMode: name of the current mode, should be in |modes|
    * @param modes: All possible modes, as keys of this dictionary
    * @param onNewMode: function that is called when the mode changes, and given the new mode name
    */
    shared bool Strings(
        const string &in label,
        const string &in currentMode,
        const dictionary@ const modes,
        OnNewModeName@ const onNewMode)
    {
        return Strings(label, currentMode, modes.GetKeys(), onNewMode);
    }
}
