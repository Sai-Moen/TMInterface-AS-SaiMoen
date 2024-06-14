namespace Interface
{
    bool enabled = false;

    void Toggle()
    {
        enabled = !enabled;
    }

    void Render()
    {
        if (enabled) gui::Render();
    }
}
