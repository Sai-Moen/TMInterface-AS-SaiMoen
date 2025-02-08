// Simulate (Ramm/Blue) bug

const string ID = "sim_bug";
const string CMD = "bug";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Simulate Bug";
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    RegisterCustomCommand(CMD, "Use: " + CMD + " help", OnCommand);
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

    vec3 speed;
    if (speeds.Get(key, speed))
    {
        DoBugSpeed(speed, simManager);
    }
}

namespace cmd
{
    const string HELP = "help";
    const string ROTATE = "rotate";
    const string SPEED = "speed";
    const string REMOVE = "remove";
    const string LIST = "list";
}

const string BUG_NAME_ROTATION = "rotation";
const string BUG_TYPE_ROTATIONS = "rotations";
dictionary rotations;

const string BUG_NAME_SPEED = "speed";
const string BUG_TYPE_SPEEDS = "speeds";
dictionary speeds;

void OnCommand(int timeFrom, int, const string &in, const array<string> &in args)
{
    uint offset = 0;
    if (args.IsEmpty())
    {
        LogHelp(Severity::Warning);
        return;
    }

    const string cmd = args[0];
    offset += 1; // first element is now taken by cmd
    if (cmd == cmd::HELP)
    {
        LogHelp();
    }
    else if (cmd == cmd::ROTATE)
    {
        OnCommandRotate(timeFrom, args, offset);
    }
    else if (cmd == cmd::SPEED)
    {
        OnCommandSpeed(timeFrom, args, offset);
    }
    else if (cmd == cmd::REMOVE)
    {
        OnCommandRemove(timeFrom, args, offset);
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
    log(cmd::SPEED + " - adds speed to the car in a certain direction", severity);
    log(cmd::REMOVE + " - removes the prepended timestamp from the given type of bug", severity);
    log(cmd::LIST + " - lists all timestamps at which bugs occur", severity);
    log("", severity); // xdd

    LogBugTypes(severity);
}

const string INDENT = "    ";

void LogBugTypes(Severity severity = Severity::Info)
{
    log("Available types of bugs:", severity);
    log(    INDENT + BUG_TYPE_ROTATIONS, severity);
    log(    INDENT + BUG_TYPE_SPEEDS, severity);
}

const int INVALID_TIME = -1;

void OnCommandRotate(int timeFrom, const array<string> &in args, uint offset)
{
    if (args.Length < offset + 3)
    {
        log(cmd::ROTATE + " needs a vec3 (e.g. bug rotate 6 2 4)", Severity::Error);
        return;
    }

    vec3 rotation = ArgsToVec3(args, offset);
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

void OnCommandSpeed(int timeFrom, const array<string> &in args, uint offset)
{
    if (args.Length < offset + 3)
    {
        log(cmd::SPEED + " needs a vec3 (e.g. bug speed 15 5 10)", Severity::Error);
        return;
    }

    vec3 speed = ArgsToVec3(args, offset);
    log("Speed vector = " + speed.ToString(), Severity::Success);

    if (timeFrom == INVALID_TIME)
    {
        DoBugSpeed(speed);
        return;
    }

    const string key = timeFrom;
    speeds[key] = speed;
    log("Added " + BUG_NAME_SPEED + " at " + key, Severity::Success);
}

void OnCommandRemove(int timeFrom, const array<string> &in args, uint offset)
{
    if (args.Length < offset + 1)
    {
        const Severity severity = Severity::Error;
        log("Specify the type of bug from which to remove a timestamp:", severity);
        LogBugTypes(severity);
        return;
    }

    dictionary@ d;
    string bugName;

    const string bugType = args[offset];
    if (bugType == BUG_TYPE_ROTATIONS)
    {
        @d = rotations;
        bugName = BUG_NAME_ROTATION;
    }
    else if (bugType == BUG_TYPE_SPEEDS)
    {
        @d = speeds;
        bugName = BUG_NAME_SPEED;
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
    LogBugList("Rotations", rotations);
    LogBugList("Speeds", speeds);
}

vec3 ArgsToVec3(const array<string> &in args, uint offset)
{
    return Text::ParseVec3(Text::Join({args[offset], args[offset + 1], args[offset + 2]}, " "));
}

void LogBugList(const string &in name, const dictionary@ const bugs)
{
    log("-- " + name + " --");
    const auto@ const keys = bugs.GetKeys();
    for (uint i = 0; i < keys.Length; i++)
    {
        const string key = keys[i];
        const vec3 value = vec3(bugs[key]);
        log(key + ": " + value.ToString());
    }
    log("----");
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
    mat3 rot = curr.Location.Rotation;
    AddLocalVector(rot, curr.AngularSpeed, rotation);
}

void DoBugSpeed(const vec3 speed, SimulationManager@ simManager = GetSimulationManager())
{
    const auto@ const dyna = simManager.Dyna;
    if (dyna is null)
    {
        log("Could not execute " + BUG_NAME_SPEED, Severity::Warning);
        return;
    }

    auto@ const curr = dyna.RefStateCurrent;
    mat3 rot = curr.Location.Rotation;
    AddLocalVector(rot, curr.LinearSpeed, speed);
}

void AddLocalVector(mat3& rot, vec3& global, const vec3 additive)
{
    rot.Transpose();
    vec3 local = RotateVector(rot, global) + additive;
    rot.Transpose();
    global = RotateVector(rot, local);
}

vec3 RotateVector(const mat3 &in rot, const vec3 v)
{
    return vec3(Math::Dot(v, rot.x), Math::Dot(v, rot.y), Math::Dot(v, rot.z));
}
