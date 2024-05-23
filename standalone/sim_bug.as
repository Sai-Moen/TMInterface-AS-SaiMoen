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

const int INVALID_TIME = -1;

const string INDENT = "    ";

namespace cmd
{
    const string HELP = "help";
    const string ROTATE = "rotate";
    const string REMOVE = "remove";
    const string LIST = "list";
}

const string BUG_NAME_ROTATION = "rotation";
const string BUG_TYPE_ROTATIONS = "rotations";
dictionary rotations;

void OnCommand(int timeFrom, int, const string &in, const array<string> &in args)
{
    if (args.IsEmpty())
    {
        LogHelp(Severity::Warning);
        return;
    }

    const string cmd = args[0];
    if (cmd == cmd::HELP)
    {
        LogHelp();
    }
    else if (cmd == cmd::ROTATE)
    {
        OnCommandRotate(timeFrom, args);
    }
    else if (cmd == cmd::REMOVE)
    {
        OnCommandRemove(timeFrom, args);
    }
    else if (cmd == cmd::LIST)
    {
        OnCommandList();
    }
    else
    {
        LogHelp(Severity::Error);
    }
}

void LogHelp(Severity severity = Severity::Info)
{
    log("Available Commands:", severity);
    log(cmd::HELP + " - log this message", severity);
    log(cmd::ROTATE + " - rotate the car in a certain direction", severity);
    log(cmd::REMOVE + " - removes the prepended timestamp from the given type of bug", severity);
    log(cmd::LIST + " - lists all timestamps at which bugs occur", severity);
    log("", severity); // xdd

    LogBugTypes(severity);
}

void LogBugTypes(Severity severity = Severity::Info)
{
    log("Available types of bugs:", severity);
    log(    INDENT + BUG_TYPE_ROTATIONS, severity);
}

void OnCommandRotate(int timeFrom, const array<string> &in args)
{
    if (args.Length < 4)
    {
        log(cmd::ROTATE + " needs a vector (e.g. bug rotate 6 2 4)", Severity::Error);
        return;
    }

    vec3 rotation = Text::ParseVec3(Text::Join({ args[1], args[2], args[3] }, " "));
    log("Rotation vector = " + rotation.ToString(), Severity::Success);

    if (timeFrom == INVALID_TIME)
    {
        DoBugRotation(rotation);
        return;
    }

    const string key = timeFrom;
    rotations[key] = rotation;
    log("Added " + BUG_NAME_ROTATION + " at " + key, Severity::Success);
}

void OnCommandRemove(int timeFrom, const array<string> &in args)
{
    if (args.Length < 2)
    {
        const Severity severity = Severity::Error;
        log("Specify the type of bug from which to remove a timestamp:", severity);
        LogBugTypes(severity);
        return;
    }

    dictionary@ d;
    string bugName;

    const string bugType = args[1];
    if (bugType == BUG_TYPE_ROTATIONS)
    {
        @d = rotations;
        bugName = BUG_NAME_ROTATION;
    }
    else
    {
        LogBugTypes(Severity::Error);
        return;
    }

    if (timeFrom == INVALID_TIME)
    {
        d.DeleteAll();
        log("Removed all timestamps for " + bugType, Severity::Success);
        return;
    }

    const string key = timeFrom;
    if (d.Delete(key))
    {
        log("Removed " + bugName + " at " + key, Severity::Success);
    }
    else
    {
        log("The timestamp was not found and could therefore not be removed: " + key, Severity::Warning);
    }
}

void OnCommandList()
{
    log("-- Rotations --");
    const auto@ const keys = rotations.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        const vec3 value = vec3(rotations[key]);
        log(key + ": " + value.ToString());
    }
    log("----");
}

void OnRunStep(SimulationManager@ simManager)
{
    const int time = simManager.RaceTime;

    const string key = time;
    vec3 rotation;
    if (rotations.Get(key, rotation))
    {
        DoBugRotation(rotation, simManager);
    }
}

void DoBugRotation(const vec3 rotation, SimulationManager@ simManager = GetSimulationManager())
{
    const auto@ const dyna = simManager.Dyna;
    if (dyna is null)
    {
        log("Could not execute " + BUG_NAME_ROTATION, Severity::Warning);
        return;
    }

    auto@ const curr = dyna.RefStateCurrent;
    vec3 aspeed = curr.AngularSpeed;
    aspeed += rotation;
    curr.AngularSpeed = RotateAngularSpeed(curr.Location.Rotation, aspeed);
}

vec3 RotateAngularSpeed(mat3 rot, vec3 aspeed)
{
    return vec3(Math::Dot(aspeed, rot.x), Math::Dot(aspeed, rot.y), Math::Dot(aspeed, rot.z));
}
