namespace smnu::UI::TabBar
{
    /**
    * Draws a UI::TabBar based on the given {string}s.
    * @param label: label of the TabBar
    * @param tabs: names of all open tabs
    * @param onModeName: function that is called with a name when the corresponding tab is open
    * @ret: the return value of UI::BeginTabBar
    */
    shared bool Strings(const string &in label, const array<string>@ const tabs, OnModeName@ const onModeName)
    {
        const bool value = UI::BeginTabBar(label);
        if (value)
        {
            for (uint i = 0; i < tabs.Length; i++)
            {
                const string tab = tabs[i];
                if (UI::BeginTabItem(tab))
                {
                    onModeName(tab);
                    UI::EndTabItem();
                }
            }

            UI::EndTabBar();
        }
        return value;
    }

    /**
    * Draws a UI::TabBar based on the given {string}s.
    * @param label: label of the TabBar
    * @param tabs: dictionary with the tab names as keys
    * @param onModeName: function that is called with a name when the corresponding tab is open
    * @ret: whether the TabBar was drawn
    */
    shared bool Strings(const string &in label, const dictionary@ const tabs, OnModeName@ const onModeName)
    {
        return Strings(label, tabs.GetKeys(), onModeName);
    }
}
