namespace smnu::UI
{
    /**
    * Draws a part of the window inside of a tooltip.
    * @param window: (part of) a window
    * @ret: the return value of UI::EndTooltip, or false if no tooltip
    */
    shared bool Tooltip(Window@ const window)
    {
        if (UI::BeginTooltip())
        {
            window();
            return UI::EndTooltip();
        }

        return false;
    }
}
