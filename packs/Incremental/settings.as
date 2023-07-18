// Settings/vars/ui Script

const string VAR_PREFIX = "saimoen_";

// General vars
const string MODE      = VAR_PREFIX + "mode";
const string TIME_FROM = VAR_PREFIX + "time_from";
const string TIME_TO   = VAR_PREFIX + "time_to";
const string DIRECTION = VAR_PREFIX + "direction";

enum Direction
{
    left,
    right,
}

string mode;
int timeFrom;
int timeTo;
int direction;

void SetupSettings()
{
    RegisterVariable(MODE, MODE_NONE);
    RegisterVariable(TIME_FROM, 0);
    RegisterVariable(TIME_TO, 10000);
    RegisterVariable(DIRECTION, 0);

    mode = GetVariableString(MODE);
    @funcs = GetScriptFuncs(mode);

    modes = funcMap.GetKeys();
    modes.SortAsc();
}

void DrawSettings()
{
    if (UI::CollapsingHeader("General"))
    {
        timeFrom  = UI::InputTimeVar("Time to start at", TIME_FROM);
        timeTo    = UI::InputTimeVar("Time to stop at", TIME_TO);
        direction = UI::SliderIntVar("Direction", DIRECTION, Direction::left, Direction::right, "");
        direction = direction == Direction::left ? -1 : 1;
    }

    if (UI::CollapsingHeader("Modes"))
    {
        if (UI::BeginCombo("Mode", mode))
        {
            for (uint i = 0; i < modes.Length; i++)
            {
                string newMode = modes[i];
                if (UI::Selectable(newMode, mode == newMode))
                {
                    SetVariable(MODE, newMode);
                    mode = newMode;
                    @funcs = GetScriptFuncs(newMode);
                }
            }

            UI::EndCombo();
        }
        funcs.settings();
    }
}
