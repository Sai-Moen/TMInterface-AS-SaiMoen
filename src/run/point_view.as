// Point View

const string ID = "point_view";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "View Point";
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    OnRegister();
    RegisterSettingsPage(ID, Window);
}

const int INVALID_ID = -1;
int id = INVALID_ID;

void OnDisabled()
{
    if (id != INVALID_ID)
    {
        RemoveTrigger(id);
        id = INVALID_ID;
    }
}

const string PREFIX = ID + "_";

const string ENABLED = PREFIX + "enabled";
const string SIZE = PREFIX + "size";

bool enabled;
vec3 radius;
vec3 diameter;
vec3 Size { set { radius = value / 2; diameter = value; } }

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(SIZE, 1);

    enabled = GetVariableBool(ENABLED);
    Size = vec3(GetVariableDouble(SIZE));
}

vec3 position;

void Render()
{
    if (!enabled) return;

    const vec3 updated = GetPoint() - radius;
    if (updated != position || id == INVALID_ID)
    {
        const auto trigger = Trigger3D(updated, diameter);
        if (trigger)
        {
            position = updated;
            id = SetTrigger(trigger, id);
        }
    }
}

vec3 GetPoint()
{
    return Text::ParseVec3(GetVariableString("bf_target_point"));
}

void Window()
{
    if (UI::CheckboxVar("Enable point view", ENABLED))
    {
        enabled = true;
        Size = vec3(UI::InputFloatVar("Size", SIZE));
    }
    else if (enabled)
    {
        enabled = false;
        OnDisabled();
    }
}
