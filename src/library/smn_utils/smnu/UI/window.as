namespace smnu::UI
{
    /**
    * Draws a window with the given |title| and draws using the window.
    * @param window: function to call when the window is open
    * @param title: title of the window
    * @ret: the return value of UI::End
    */
    shared bool Draw(Window@ const window, const string &in title)
    {
        if (UI::Begin(title))
        {
            window();
        }
        return UI::End();
    }

    /**
    * Draws a window with the given |title| if enabled, and draws using the window.
    * @param window: function to call when the window is open
    * @param title: title of the window
    * @param enabled: whether the window should be enabled (visible)
    * @ret: the return value of UI::End, or false if not enabled
    */
    shared bool Draw(Window@ const window, const string &in title, const bool enabled)
    {
        return enabled && Draw(window, title);
    }
}
