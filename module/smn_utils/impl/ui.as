namespace smnu::UI
{
    // What to do when a new mode is selected in the Combo
    shared funcdef void OnNewMode(const string &in newMode);

    // Draws a UI::Combo based on the given parameters
    // param label: label of the Combo
    // param currentMode: The current mode, should be in allModes
    // param allModes: All possible modes
    // param onNewMode: function that is called when the mode changes, and given the new mode name
    // returns: whether the combo is open
    shared bool ComboHelper(
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

    // Makes object describable
    // prop Name: name of the object
    // prop Description: describes the object
    shared interface Describable
    {
        const string Name { get const; }
        const string Description { get const; }
    }

    // See full function
    shared void DescribeModes(const string &in label, const dictionary@ const map)
    {
        DescribeModes(label, map, map.GetKeys());
    }

    // Draws a tooltip describing the modes
    // param label: text that appears at the top of the tooltip
    // param map: dictionary containing describable objects
    // param modes: keys of map
    shared void DescribeModes(
        const string &in label,
        const dictionary@ const map,
        const array<string>@ const modes)
    {
        UI::BeginTooltip();
        UI::Text(label);
        for (uint i = 0; i < modes.Length; i++)
        {
            const Describable@ const desc = cast<Describable>(map[modes[i]]);
            UI::Text(desc.Name + " - " + desc.Description);
        }
        UI::EndTooltip();
    }

    // Sets the variable to the highest of the two times
    // Useful when working with InputTime-related UI widgets
    // param variableName: name of the variable
    // param tfrom: time_from
    // param tto: time_to
    shared void CapMax(const string &in variableName, const ms tfrom, const ms tto)
    {
        SetVariable(variableName, Math::Max(tfrom, tto));
    }
}
