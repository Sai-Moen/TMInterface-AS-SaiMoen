// UI Script, User-Interface code

const string VAR_PREFIX = "saimoen_";

// General vars
const string MODE      = VAR_PREFIX + "mode";
const string TIME_FROM = VAR_PREFIX + "time_from";
const string TIME_TO   = VAR_PREFIX + "time_to";
const string DIRECTION = VAR_PREFIX + "direction";
const string AUTO_SEEK = VAR_PREFIX + "auto_seek";
const string SEEK      = VAR_PREFIX + "seek";

enum Direction
{
    left,
    right,
}

void RegisterUI()
{
    RegisterVariable(MODE, none.name);
    RegisterVariable(TIME_FROM, 0);
    RegisterVariable(TIME_TO, 10000);
    RegisterVariable(DIRECTION, 0);
    RegisterVariable(AUTO_SEEK, true);
    RegisterVariable(SEEK, SEEK_MS);

    string currentMode = GetVariableString(MODE);
    @funcs = GetScriptFuncs(currentMode);
}

void DrawSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        UI::InputTimeVar("Time to start at", TIME_FROM);
        UI::InputTimeVar("Time to stop at", TIME_TO);
        UI::SliderIntVar("Direction", DIRECTION, Direction::left, Direction::right, "");

        bool autoSeek = UI::CheckboxVar("Use automatic seek?", AUTO_SEEK);
        UI::BeginDisabled(autoSeek);
        UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK_MS);
        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Modes"))
    {
        string currentMode = GetVariableString(MODE);
        if (UI::BeginCombo("Mode", currentMode))
        {
            array<string> modes = funcMap.GetKeys();
            modes.SortAsc();
            for (uint i = 0; i < modes.Length; i++)
            {
                string newMode = modes[i];
                if (UI::Selectable(newMode, currentMode == newMode))
                {
                    SetVariable(MODE, newMode);
                    @funcs = GetScriptFuncs(newMode);
                }
            }

            UI::EndCombo();
        }
        funcs.settings();
    }
}
