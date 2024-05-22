// Simulate (Ramm/Blue) bug

const string ID = "sim_bug";
const string CMD = "bug";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Simulate Bug";
    info.Version = "v2.0.1.0";
    return info;
}

void Main()
{
    RegisterCustomCommand(CMD, "Use: " + CMD + " help", OnCommand);
}

const string INDENT = "    ";

const string HELP = "help";
const string ROTATE = "rotate";
const string STRENGTH = "strength";

const int INVALID_TIME = -1;
int whenthe = INVALID_TIME;

const vec3 DEFAULT_STRENGTH = vec3(6, 2, 4);
vec3 strength = DEFAULT_STRENGTH;

void OnCommand(int t, int, const string &in, const array<string> &in args)
{
    if (args.IsEmpty())
    {
        LogHelp();
        return;
    }

    const string cmd = args[0];
    if (cmd == HELP)
    {
        LogHelp();
    }
    else if (cmd == ROTATE)
    {
        whenthe = t;
        if (whenthe == INVALID_TIME)
        {
            DoBug();
        }
        else
        {
            log("Time = " + whenthe, Severity::Success);
        }
    }
    else if (cmd == STRENGTH)
    {
        if (args.Length < 4)
        {
            log(STRENGTH + " needs a vector (default " + DEFAULT_STRENGTH.ToString() + ") as a sub-argument.", Severity::Error);
            return;
        }

        if (t != INVALID_TIME)
        {
            log(STRENGTH + " ignored the given time parameter " + t + " ...", Severity::Warning);
        }

        strength = Text::ParseVec3(Text::Join({ args[1], args[2], args[3] }, " "));
        log("Strength = " + strength.ToString(), Severity::Success);
    }
    else
    {
        LogHelp();
    }
}

void LogHelp()
{
    log("Available Commands:");
    log(HELP + " - log this message");
    log(ROTATE + " - rotate the car in a certain direction");
    log(STRENGTH + " - sets strength of the bug (default " + DEFAULT_STRENGTH.ToString() + ")");
}

void OnRunStep(SimulationManager@ simManager)
{
    const int time = simManager.RaceTime;
    if (time == whenthe)
    {
        DoBug(simManager);
    }
}

void DoBug(SimulationManager@ simManager = GetSimulationManager())
{
    auto@ const curr = simManager.Dyna.RefStateCurrent;
    vec3 aspeed = curr.AngularSpeed;
    aspeed += strength;
    curr.AngularSpeed = RotateAngularSpeed(curr.Location.Rotation, aspeed);
}

vec3 RotateAngularSpeed(mat3 rot, vec3 aspeed)
{
    return vec3(Math::Dot(rot.x, aspeed), Math::Dot(rot.y, aspeed), Math::Dot(rot.z, aspeed));
}
