namespace smnu::UI
{
    /**
    * Draws a part of the window that can be disabled.
    * @param window: (part of) a window
    * @param disabled: whether to disable |window|
    * @ret: the return value of UI::EndDisabled, or false if not disabled
    */
    shared bool Disabled(Window@ const window, const bool disabled = true)
    {
        if (UI::BeginDisabled(disabled))
        {
            window();
            return UI::EndDisabled();
        }

        return false;
    }
}
