PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = "Introspect";
    info.Description = "Introspection of game state";
    info.Version = "v3.0.0";
    return info;
}

void Main()
{
    RegisterSettings();
    RegisterSettingsPage("Introspect Settings", SettingsPage);
}

const string VAR = "introspect_";

const string VAR_VIEW_IEB        = VAR + "view_ieb";
const string VAR_RAW_IEB         = VAR + "raw_ieb";
const string VAR_REVERSE_RAW_IEB = VAR + "reverse_raw_ieb";
const string VAR_ORIGINAL_ANALOG = VAR + "original_analog";

const string VAR_VIEW_STATE = VAR + "view_state";
const string VAR_SPAM       = VAR + "spam";

void RegisterSettings()
{
    RegisterVariable(VAR_VIEW_IEB,        false);
    RegisterVariable(VAR_RAW_IEB,         false);
    RegisterVariable(VAR_REVERSE_RAW_IEB, false);
    RegisterVariable(VAR_ORIGINAL_ANALOG, false);

    RegisterVariable(VAR_VIEW_STATE, false);
    RegisterVariable(VAR_SPAM,       false);
}

void Render()
{
    if (VarGetBool(VAR_VIEW_IEB))
    {
        if (UI::Begin("Introspect IEB", UI::WindowFlags::NoTitleBar))
            ViewIEB();
        UI::End();
    }

    if (VarGetBool(VAR_VIEW_STATE))
    {
        if (UI::Begin("Introspect SaveState", UI::WindowFlags::NoTitleBar))
            ViewSaveState();
        UI::End();
    }
}

void SettingsPage()
{
    if (UI::CollapsingHeader("Input Event Buffer"))
    {
        UI::CheckboxVar("View", VAR_VIEW_IEB);
        TooltipOnHover("[Creates a window] View the Input Event Buffer's state.");

        UI::CheckboxVar("Raw Input Events", VAR_RAW_IEB);
        TooltipOnHover("Display raw input events, not the TMInterface syntax.");

        UI::CheckboxVar("[Raw] Reverse", VAR_REVERSE_RAW_IEB);
        TooltipOnHover("Display raw input events in reverse.");

        UI::CheckboxVar("[Raw] Original Analog", VAR_ORIGINAL_ANALOG);
        TooltipOnHover("Display the original analog values for steer/gas, without the negation applied by TMInterface.");
    }

    if (UI::CollapsingHeader("State"))
    {
        UI::CheckboxVar("View", VAR_VIEW_STATE);
        TooltipOnHover("[Creates a window] View the current race's state with the structure of a save state.");

        UI::CheckboxVar("Spam", VAR_SPAM);
        TooltipOnHover("Spams the console with 4 bytes starting from the current offset.");
    }
}

void OnRunStep(SimulationManager@ sim)
{
    if (!VarGetBool(VAR_VIEW_STATE))
    {
        @state = null;
        return;
    }

    @state = sim.SaveState().ToArray();
}
