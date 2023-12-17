namespace smnu::UI::Combo
{
    // Draws a UI::Combo based on the given Handles
    // param label: label of the Combo
    // param currentMode: name of the current mode, should be in modes
    // param modes: dictionary holding Handle objects
    // param onNewMode: function that is called when the mode changes, and given the new Handle
    // returns: the return value of UI::EndCombo, or false if no combo
    shared bool Handles(
        const string &in label,
        const string &in currentMode,
        const dictionary@ const modes,
        OnNewMode@ const onNewMode)
    {
        if (UI::BeginCombo(label, currentMode))
        {
            Handle@ const curr = CastToHandle(modes[currentMode]);

            const array<string>@ const keys = modes.GetKeys();
            for (uint i = 0; i < keys.Length; i++)
            {
                const string key = keys[i];
                Handle@ const handle = CastToHandle(modes[key]);
                if (UI::Selectable(key, handle is curr))
                {
                    onNewMode(handle);
                }
            }

            return UI::EndCombo();
        }

        return false;
    }

    // See full function
    shared bool Strings(
        const string &in label,
        const string &in currentMode,
        const dictionary@ const modes,
        OnNewModeName@ const onNewMode)
    {
        return Strings(label, currentMode, modes.GetKeys(), onNewMode);
    }

    // Draws a UI::Combo based on the given strings
    // param label: label of the Combo
    // param currentMode: name of the current mode, should be in modes
    // param modes: All possible modes
    // param onNewMode: function that is called when the mode changes, and given the new mode name
    // returns: the return value of UI::EndCombo, or false if no combo
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
}
