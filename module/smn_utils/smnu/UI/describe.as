namespace smnu::UI
{
    // Makes object describable
    // prop Name: name of the object
    // prop Description: describes the object
    shared interface Describable
    {
        string Name { get const; }
        string Description { get const; }
    }

    // Determines how to describe a Describable object
    shared funcdef void DescribeMode(const Describable@ const);

    // Creates a text widget that describes the given mode
    // param desc: Describable object
    shared void DefaultDescribeMode(const Describable@ const desc)
    {
        UI::Text(desc.Name + " - " + desc.Description);
    }

    // See full function
    shared bool DescribeModes(const string &in label, const array<Describable@>@ const modes)
    {
        return DescribeModes(label, modes, DefaultDescribeMode);
    }

    // Draws a tooltip describing the modes
    // param label: text that appears at the top of the tooltip
    // param modes: array of describable objects
    // param dm: callback to describe a mode
    // returns: the return value of UI::EndTooltip, or false if no tooltip
    shared bool DescribeModes(const string &in label, const array<Describable@>@ const modes, DescribeMode@ const dm)
    {
        if (UI::BeginTooltip())
        {
            UI::Text(label);
            for (uint i = 0; i < modes.Length; i++)
            {
                Describable@ const mode = modes[i];
                if (mode is null)
                {
                    UI::Text(string());
                    continue;
                }

                dm(mode);
            }

            return UI::EndTooltip();
        }

        return false;
    }

    // See full function
    shared bool DescribeModes(const string &in label, const dictionary@ const map)
    {
        return DescribeModes(label, map, DefaultDescribeMode);
    }

    // Draws a tooltip describing the modes of the dictionary
    // param label: text that appears at the top of the tooltip
    // param map: dictionary of describable objects
    // param dm: callback to describe a mode
    // returns: the return value of UI::EndTooltip, or false if no tooltip
    shared bool DescribeModes(const string &in label, const dictionary@ const map, DescribeMode@ const dm)
    {
        array<Describable@>@ const descs = array<Describable@>(map.GetSize());

        const array<string>@ const modes = map.GetKeys();
        for (uint i = 0; i < modes.Length; i++)
        {
            @descs[i] = cast<Describable@>(map[modes[i]]);
        }
        
        return DescribeModes(label, descs, dm);
    }
}
