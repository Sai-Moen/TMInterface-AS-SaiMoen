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

const string HELP = "help";
const string ROTATE = "rotate";
const string STRENGTH = "strength";

const string FWD = "forwards";
const string BWD = "backwards";

const string INDENT = "    ";
const int INVALID_TIME = -1;

double direction = 0;
int whenthe = INVALID_TIME;

double strength = 8;

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
        if (args.Length <= 1)
        {
            log(ROTATE + " needs one of the following sub-arguments:", Severity::Error);
            log(    INDENT + FWD, Severity::Error);
            log(    INDENT + BWD, Severity::Error);
            return;
        }

        const string arg = args[1];
        if (arg == FWD)      direction = 1;
        else if (arg == BWD) direction = -1;
        log("Direction = " + direction, Severity::Success);

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
        if (args.Length <= 1)
        {
            log(STRENGTH + " needs a value (default 8) as a sub-argument.", Severity::Error);
            return;
        }

        if (t != INVALID_TIME)
        {
            log(STRENGTH + " ignored the given time parameter " + t + " ...", Severity::Warning);
        }

        const string arg = args[1];
        strength = Text::ParseFloat(arg);
        log("Strength = " + strength, Severity::Success);
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
    log(    INDENT + FWD);
    log(    INDENT + BWD);
    log(STRENGTH + " - sets strength of the bug (default 8)");
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
    aspeed.x += direction * strength;
    curr.AngularSpeed = RotateAngularSpeed(curr.Location.Rotation, aspeed);
}

vec3 RotateAngularSpeed(mat3 rot, vec3 aspeed)
{
    return vec3(Math::Dot(rot.x, aspeed), Math::Dot(rot.y, aspeed), Math::Dot(rot.z, aspeed));
}
