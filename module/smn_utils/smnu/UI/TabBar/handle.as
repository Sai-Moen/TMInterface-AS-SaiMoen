namespace smnu::UI::TabBar
{
    /**
    * Draws a UI::TabBar based on the given {Handle}s.
    * @param label: label of the TabBar
    * @param modes: dictionary holding {Handle} objects
    * @param onMode: function that is called when the mode is selected, and given the corresponding {Handle}
    * @ret: whether the TabBar was drawn
    */
    shared bool Handles(const string &in label, const dictionary@ const modes, OnMode@ const onMode)
    {
        const bool value = UI::BeginTabBar(label);
        if (value)
        {
            const array<string>@ const keys = modes.GetKeys();
            for (uint i = 0; i < keys.Length; i++)
            {
                const string key = keys[i];
                if (UI::BeginTabItem(key))
                {
                    onMode(CastToHandle(modes[key]));
                    UI::EndTabItem();
                }
            }

            UI::EndTabBar();
        }
        return value;
    }

    /**
    * Draws a UI::TabBar based on the given array of {HandleStr}s.
    * @param label: label of the TabBar
    * @param modes: array of {HandleStr}s
    * @param onMode: function that is called when the mode is selected, and given the corresponding {Handle}
    * @ret: whether the TabBar was drawn
    */
    shared bool HandleStrs(const string &in label, const array<HandleStr@>@ const modes, OnMode@ const onMode)
    {
        const bool value = UI::BeginTabBar(label);
        if (value)
        {
            for (uint i = 0; i < modes.Length; i++)
            {
                HandleStr@ const handle = modes[i];
                if (UI::BeginTabItem(string(handle)))
                {
                    onMode(handle);
                    UI::EndTabItem();
                }
            }

            UI::EndTabBar();
        }
        return value;
    }
}
