namespace smnu::UI::Combo
{
    /**
    * Draws a UI::Combo based on the given {Handle}s.
    * @param label: label of the Combo
    * @param currentMode: name of the current mode, should be in |modes|
    * @param modes: dictionary holding {Handle} objects
    * @param onNewMode: function that is called when the mode changes, and given the new {Handle}
    * @ret: the return value of UI::EndCombo, or false if no combo
    */
    shared bool Handles(
        const string &in label,
        const string &in currentMode,
        const dictionary@ const modes,
        OnNewMode@ const onNewMode)
    {
        bool value;
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

            value = UI::EndCombo();
        }
        return value;
    }

    /**
    * Draws a UI::Combo based on the given {Stringifiable}s.
    * @param label: label of the Combo
    * @param curr: current mode, can be converted to string representation for the Combo
    * @param modes: dictionary holding {Handle} objects
    * @param onNewMode: function that is called when the mode changes, and given the new {Handle}
    * @ret: the return value of UI::EndCombo, or false if no combo
    */
    shared bool HandleStrs(
        const string &in label,
        const Stringifiable@ const curr,
        const dictionary@ const modes,
        OnNewMode@ const onNewMode)
    {
        bool value;
        if (UI::BeginCombo(label, string(curr)))
        {
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

            value = UI::EndCombo();
        }
        return value;
    }
}
