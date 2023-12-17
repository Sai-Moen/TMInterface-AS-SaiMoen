namespace smnu::UI
{
    // What to do when a new mode is selected
    shared funcdef void OnNewMode(Handle@ const);
    shared funcdef void OnNewModeName(const string &in);

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
