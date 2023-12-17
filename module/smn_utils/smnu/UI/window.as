namespace smnu::UI
{
    // Callback that will draw the UI inside the window
    shared funcdef void Window();

    // See full function
    shared bool Draw(Window@ const window, const string &in name)
    {
        if (UI::Begin(name))
        {
            window();
        }
        return UI::End();
    }

    // Creates a window with the given name if enabled, and draws using the window
    // param window: function to call when the window is open
    // param name: name of the window
    // param enabled: whether the window should be enabled (visible)
    // returns: the return value of UI::End, or false if not enabled
    shared bool Draw(Window@ const window, const string &in name, const bool enabled)
    {
        return enabled && Draw(window, name);
    }
}
