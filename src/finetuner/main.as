const string ID = "finetuner";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Finetunes car properties w/ bruteforce";
    info.Version = "v2.1.1e";
    return info;
}

void Main()
{
    LogIfWrongCount();
    RegisterSettings();
    RegisterBruteforceEvaluation(ID, "Finetuner", OnEvaluate, RenderSettings);
}

bool customTargetTowards;

bool valid;
ms impTime;

double diffCurrent;
double diffBest;

double current;
vec3   current3;
double best;
vec3   best3;

funcdef bool IsBetterTargeted(SimulationManager@ simManager);
const IsBetterTargeted@ isBetter;

funcdef bool IsBetterTargetedTowards();
const IsBetterTargetedTowards@ isBetterTowards;

array<ModeKind> modeIndices;
array<ConditionKind> conditionIndices;

void OnSimulationBegin(SimulationManager@)
{
    if (!(GetVariableString("controller") == "bruteforce" && ID == GetVariableString("bf_target")))
        return;

    print("\n=========\nFinetuner\n=========\n");

    customTargetTowards = targetTowards == 0;

    if (isTargetGrouped)
    {
        switch (targetTowards)
        {
        case -1:
            @isBetterTowards =
                function()
                {
                    return current3.Length() < best3.Length();
                };
            break;
        case 0:
            @isBetterTowards =
                function()
                {
                    diffCurrent = (target3Values - current3).Length();
                    return diffCurrent < diffBest;
                };
            break;
        case 1:
            @isBetterTowards =
                function()
                {
                    return current3.Length() > best3.Length();
                };
            break;
        default:
            @isBetterTowards = function() { return false; };
            print("Bug with targetTowards...", Severity::Error);
            break;
        }

        @isBetter =
            function(simManager)
            {
                current3 = GetGroupValue(simManager, targetGroup);
                return isBetterTowards();
            };
    }
    else
    {
        switch (targetTowards)
        {
        case -1:
            @isBetterTowards =
                function()
                {
                    return current < best;
                };
            break;
        case 0:
            @isBetterTowards =
                function()
                {
                    diffCurrent = Math::Abs(targetValue - current);
                    return diffCurrent < diffBest;
                };
            break;
        case 1:
            @isBetterTowards =
                function()
                {
                    return current > best;
                };
            break;
        default:
            @isBetterTowards = function() { return false; };
            print("Bug with targetTowards...", Severity::Error);
            break;
        }

        @isBetter =
            function(simManager)
            {
                current = GetModeValue(simManager, targetMode);
                return isBetterTowards();
            };
    }

    for (uint g = 0; g < GroupKind::COUNT; g++)
    {
        const GroupKind groupKind = GroupKind(g);
        if (!groups[groupKind].active)
            continue;

        array<ModeKind> tempModeKinds;
        if (!GroupKindToModeKinds(groupKind, tempModeKinds))
            continue;

        for (uint k = 0; k < tempModeKinds.Length; k++)
        {
            const ModeKind modeKind = tempModeKinds[k];
            const Mode@ const mode = modes[modeKind];
            if (mode.lower || mode.upper)
                modeIndices.Add(modeKind);
        }
    }

    for (uint c = 0; c < ConditionKind::COUNT; c++)
    {
        const ConditionKind kind = ConditionKind(c);
        if (conditions[kind].active)
            conditionIndices.Add(kind);
    }

    {
        print("Target:");
        string strTarget;
        string strTargetValue;
        if (isTargetGrouped)
        {
            strTarget = "Group = " + groupNames[targetGroup];
            strTargetValue = "Values = " + FormatPrecise(target3Values);
        }
        else
        {
            strTarget = "Mode = " + modeNames[targetMode];
            strTargetValue = "Value = " + FormatPrecise(targetValue);
        }
        print(strTarget);
        if (customTargetTowards)
            print(strTargetValue);

        string strTargetTowards = "Towards = ";
        bool ok = true;
        switch (targetTowards)
        {
        case -1:
            strTargetTowards += "Lower value is better.";
            break;
        case 0:
            strTargetTowards += "Custom.";
            break;
        case 1:
            strTargetTowards += "Higher value is better.";
            break;
        default:
            ok = false;
            break;
        }

        if (ok)
            print(strTargetTowards);

        print(Repeat('-', strTargetTowards.Length) + "\n");
    }

    {
        print("Bounds: (actual values, so angles in radians and speeds in m/s)");
        uint maxModeNameLength = 0;
        if (modeIndices.IsEmpty())
        {
            const string NO_MODES = "None.";
            print(NO_MODES);
            maxModeNameLength = NO_MODES.Length;
        }
        else
        {
            for (uint i = 0; i < modeIndices.Length; i++)
            {
                const uint len = modeNames[modeIndices[i]].Length;
                if (maxModeNameLength < len)
                    maxModeNameLength = len;
            }

            for (uint i = 0; i < modeIndices.Length; i++)
            {
                const ModeKind kind = modeIndices[i];
                const Mode@ const mode = modes[kind];
                string builder = PadRight(modeNames[kind], maxModeNameLength) + " => ";

                if (mode.lower)
                    builder += "Lower: " + FormatPrecise(mode.lowerValue);

                if (mode.lower && mode.upper)
                    builder += ", ";

                if (mode.upper)
                    builder += "Upper: " + FormatPrecise(mode.upperValue);

                print(builder);
            }
        }
        print(Repeat('-', maxModeNameLength) + "\n");
    }

    {
        print("Conditions: (actual values)");
        uint maxConditionNameLength = 0;
        if (conditionIndices.IsEmpty())
        {
            const string NO_CONDITIONS = "None.";
            print(NO_CONDITIONS);
            maxConditionNameLength = NO_CONDITIONS.Length;
        }
        else
        {
            for (uint i = 0; i < conditionIndices.Length; i++)
            {
                const uint len = conditionNames[conditionIndices[i]].Length;
                if (maxConditionNameLength < len)
                    maxConditionNameLength = len;
            }

            for (uint i = 0; i < conditionIndices.Length; i++)
            {
                const ConditionKind kind = conditionIndices[i];
                print(PadRight(conditionNames[kind], maxConditionNameLength) + " => " + conditions[kind].value);
            }
        }
        print(Repeat('-', maxConditionNameLength) + "\n");
    }
}

void OnSimulationEnd(SimulationManager@, SimulationResult)
{
    valid = false;
    modeIndices.Clear();
    conditionIndices.Clear();
}

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    BFEvaluationResponse response;

    const ms time = simManager.RaceTime;
    switch (info.Phase)
    {
    case BFPhase::Initial:
        if (IsEvalTime(time))
        {
            if (IsBetter(simManager))
            {
                valid = true;
                impTime = time;

                best = current;
                best3 = current3;
                diffBest = diffCurrent;
            }
        }
        else if (IsPastEvalTime(time))
        {
            if (valid)
            {
                const uint iterations = info.Iterations;
                const bool isFirstIteration = iterations == 0;

                string builder;
                if (isTargetGrouped)
                    builder += groupNames[targetGroup] + " | " + FormatVec3ByTargetGroup(best3, 6);
                else
                    builder += modeNames[targetMode] + " | " + FormatFloatByTargetMode(best, 6);

                builder += " | Time: " + Time::Format(impTime);

                if (customTargetTowards)
                    builder += " | Diff: " + FormatFloatByTarget(diffBest);

                if (!isFirstIteration)
                    builder += " | Iterations: " + iterations;

                print(builder, isFirstIteration ? Severity::Info : Severity::Success);
            }
            else
            {
                print("Base Run did not suffice...", Severity::Warning);
            }
            response.Decision = BFEvaluationDecision::Accept;
        }
        break;
    case BFPhase::Search:
        if (IsEvalTime(time))
        {
            if (IsBetter(simManager))
                response.Decision = BFEvaluationDecision::Accept;
        }
        else if (IsPastEvalTime(time))
        {
            response.Decision = BFEvaluationDecision::Reject;
        }
        break;
    }

    return response;
}

bool IsEvalTime(const ms time)
{
    return evalFrom <= time && time <= evalTo;
}

bool IsPastEvalTime(const ms time)
{
    return time > evalTo;
}

bool IsBetter(SimulationManager@ simManager)
{
    const auto@ const dyna = simManager.Dyna;
    const auto@ const currentState = dyna.RefStateCurrent;
    const auto@ const previousState = dyna.RefStatePrevious;
    const double velocity = currentState.LinearSpeed.Length();

    const auto@ const svc = simManager.SceneVehicleCar;
    const auto@ const engine = svc.CarEngine;

    const auto@ const playerInfo = simManager.PlayerInfo;

    for (uint i = 0; i < conditionIndices.Length; i++)
    {
        const ConditionKind kind = conditionIndices[i];
        const Condition@ const condition = conditions[kind];
        switch (kind)
        {
        case ConditionKind::MIN_REAL_SPEED:
            if (velocity < condition.value)
                return false;

            break;
        case ConditionKind::FREEWHEELING:
            if (svc.IsFreeWheeling != (condition.value != 0))
                return false;

            break;
        case ConditionKind::SLIDING:
            if (svc.IsSliding != (condition.value != 0))
                return false;

            break;
        case ConditionKind::WHEEL_TOUCHING:
            if (svc.HasAnyLateralContact != (condition.value != 0))
                return false;

            break;
        case ConditionKind::WHEEL_CONTACTS:
            {
                uint contacts = 0;
                const auto@ const wheels = simManager.Wheels;
                for (uint w = 0; w < 4; w++)
                {
                    if (wheels[w].RTState.HasGroundContact)
                        contacts++;
                }

                if (contacts < uint(condition.value))
                    return false;
            }
            break;
        case ConditionKind::CHECKPOINTS:
            if (playerInfo.CurCheckpointCount != uint(condition.value))
                return false;

            break;
        case ConditionKind::GEAR:
            if (engine.Gear != int(condition.value))
                return false;

            break;
        case ConditionKind::REAR_GEAR:
            if (engine.RearGear != int(condition.value))
                return false;

            break;
        case ConditionKind::GLITCHING:
            {
                const double positionalDifference = Math::Distance(
                    previousState.Location.Position,
                    currentState.Location.Position);
                bool isGlitching = positionalDifference > 0.1 && velocity / positionalDifference < 50.0;
                if (isGlitching != (condition.value != 0))
                    return false;
            }
            break;
        default:
            print("Corrupted condition index: " + kind, Severity::Error);
            return false;
        }
    }

    for (uint i = 0; i < modeIndices.Length; i++)
    {
        const ModeKind kind = modeIndices[i];
        const double value = GetModeValue(simManager, kind);

        const Mode@ const mode = modes[kind];
        if ((mode.lower && value < mode.lowerValue) || (mode.upper && value > mode.upperValue))
            return false;
    }

    return isBetter(simManager) || !valid;
}

vec3 GetGroupValue(SimulationManager@ simManager, const GroupKind kind)
{
    vec3 value;

    const auto@ const dyna = simManager.Dyna.RefStateCurrent;
    const iso4 location = dyna.Location;
    mat3 rotation = location.Rotation;

    const auto@ const svc = simManager.SceneVehicleCar;

    const auto@ const wheels = simManager.Wheels;

    switch (kind)
    {
    case GroupKind::POSITION:
        value = location.Position;
        break;
    case GroupKind::ROTATION:
        rotation.GetYawPitchRoll(value.x, value.y, value.z);
        break;
    case GroupKind::SPEED_GLOBAL:
        value = dyna.LinearSpeed;
        break;
    case GroupKind::SPEED_LOCAL:
        value = svc.CurrentLocalSpeed;
        break;
    case GroupKind::WHEEL_FRONT_LEFT:
        value = AddOffsetToLocation(wheels.FrontLeft,  location);
        break;
    case GroupKind::WHEEL_FRONT_RIGHT:
        value = AddOffsetToLocation(wheels.FrontRight, location);
        break;
    case GroupKind::WHEEL_BACK_RIGHT:
        value = AddOffsetToLocation(wheels.BackRight,  location);
        break;
    case GroupKind::WHEEL_BACK_LEFT:
        value = AddOffsetToLocation(wheels.BackLeft,   location);
        break;
    default:
        print("Corrupted group index: " + kind, Severity::Error);
        break;
    }

    return value;
}

double GetModeValue(SimulationManager@ simManager, const ModeKind kind)
{
    double value = 0;

    const auto@ const dyna = simManager.Dyna.RefStateCurrent;
    const iso4 location = dyna.Location;
    const vec3 position = location.Position;
    mat3 rotation = location.Rotation;
    const vec3 globalSpeed = dyna.LinearSpeed;

    const auto@ const svc = simManager.SceneVehicleCar;
    const vec3 localSpeed = svc.CurrentLocalSpeed;

    const auto@ const wheels = simManager.Wheels;

    switch (kind)
    {
    case ModeKind::POSITION_X:
        value = position.x;
        break;
    case ModeKind::POSITION_Y:
        value = position.y;
        break;
    case ModeKind::POSITION_Z:
        value = position.z;
        break;
    case ModeKind::ROTATION_YAW:
        rotation.GetYawPitchRoll(value, void, void);
        break;
    case ModeKind::ROTATION_PITCH:
        rotation.GetYawPitchRoll(void, value, void);
        break;
    case ModeKind::ROTATION_ROLL:
        rotation.GetYawPitchRoll(void, void, value);
        break;
    case ModeKind::SPEED_GLOBAL_X:
        value = globalSpeed.x;
        break;
    case ModeKind::SPEED_GLOBAL_Y:
        value = globalSpeed.y;
        break;
    case ModeKind::SPEED_GLOBAL_Z:
        value = globalSpeed.z;
        break;
    case ModeKind::SPEED_LOCAL_X:
        value = localSpeed.x;
        break;
    case ModeKind::SPEED_LOCAL_Y:
        value = localSpeed.y;
        break;
    case ModeKind::SPEED_LOCAL_Z:
        value = localSpeed.z;
        break;
    case ModeKind::WHEEL_FL_X:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).x;
        break;
    case ModeKind::WHEEL_FL_Y:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).y;
        break;
    case ModeKind::WHEEL_FL_Z:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).z;
        break;
    case ModeKind::WHEEL_FR_X:
        value = AddOffsetToLocation(wheels.FrontRight, location).x;
        break;
    case ModeKind::WHEEL_FR_Y:
        value = AddOffsetToLocation(wheels.FrontRight, location).y;
        break;
    case ModeKind::WHEEL_FR_Z:
        value = AddOffsetToLocation(wheels.FrontRight, location).z;
        break;
    case ModeKind::WHEEL_BR_X:
        value = AddOffsetToLocation(wheels.BackRight,  location).x;
        break;
    case ModeKind::WHEEL_BR_Y:
        value = AddOffsetToLocation(wheels.BackRight,  location).y;
        break;
    case ModeKind::WHEEL_BR_Z:
        value = AddOffsetToLocation(wheels.BackRight,  location).z;
        break;
    case ModeKind::WHEEL_BL_X:
        value = AddOffsetToLocation(wheels.BackLeft,   location).x;
        break;
    case ModeKind::WHEEL_BL_Y:
        value = AddOffsetToLocation(wheels.BackLeft,   location).y;
        break;
    case ModeKind::WHEEL_BL_Z:
        value = AddOffsetToLocation(wheels.BackLeft,   location).z;
        break;
    default:
        print("Corrupted mode index: " + kind, Severity::Error);
        break;
    }

    return value;
}

vec3 AddOffsetToLocation(TM::SceneVehicleCar::SimulationWheel@ wheel, const iso4 &in location)
{
    const vec3 offset = wheel.SurfaceHandler.Location.Position;
    const mat3 rot = location.Rotation;
    const vec3 global = vec3(Math::Dot(offset, rot.x), Math::Dot(offset, rot.y), Math::Dot(offset, rot.z));
    return location.Position + global;
}
