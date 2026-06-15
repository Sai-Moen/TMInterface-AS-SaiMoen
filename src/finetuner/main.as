const string ID = "finetuner";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Finetunes car properties w/ bruteforce";
    info.Version = "v3.0.0";
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

bool met;

array<ScalarKind> scalarIndices;
array<ScalarKind> unmetScalarIndices;
array<ms>         unmetScalarTimes;

array<ConditionKind> conditionIndices;
array<ConditionKind> unmetConditionIndices;
array<ms>            unmetConditionTimes;

void OnSimulationBegin(SimulationManager@)
{
    if (GetVariableString("controller") != "bruteforce" || ID != GetVariableString("bf_target"))
        return;

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
                    switch (targetGroup)
                    {
                    case GroupKind::ROTATION:
                        {
                            quat p, q;
                            p.SetYawPitchRoll(targetVec3.x, targetVec3.y, targetVec3.z);
                            q.SetYawPitchRoll(current3.x, current3.y, current3.z);
                            diffCurrent = QuatAngle(p, q);
                        }
                    break;
                    default:
                        diffCurrent = Math::Distance(current3, targetVec3);
                    break;
                    }
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
                    const double diff = current - targetValue;
                    switch (targetScalar)
                    {
                    case ScalarKind::ROTATION_YAW:
                    case ScalarKind::ROTATION_PITCH:
                    case ScalarKind::ROTATION_ROLL:
                        diffCurrent = Math::Min(Math::Abs(diff), Math::Abs(diff + Math::PI * 2));
                    break;
                    default:
                        diffCurrent = Math::Abs(diff);
                    break;
                    }
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
                current = GetScalarValue(simManager, targetScalar);
                return isBetterTowards();
            };
    }

    for (uint g = 0; g < GroupKind::COUNT; g++)
    {
        const GroupKind groupKind = GroupKind(g);
        if (!groups[groupKind].active)
            continue;

        const auto@ const tempScalarKinds = GroupKindToScalarKinds(groupKind);
        for (uint k = 0; k < tempScalarKinds.Length; k++)
        {
            const ScalarKind scalarKind = tempScalarKinds[k];
            const Scalar@ const scalar = scalars[scalarKind];
            if (scalar.lower || scalar.upper)
                scalarIndices.Add(scalarKind);
        }
    }

    for (uint c = 0; c < ConditionKind::COUNT; c++)
    {
        const ConditionKind kind = ConditionKind(c);
        if (conditions[kind].active)
            conditionIndices.Add(kind);
    }

    string s;
    s += "\n=========\n";
    s += "Finetuner";
    s += "\n=========\n\n";

    {
        s += "Target:\n";
        if (isTargetGrouped)
        {
            s += "Group = ";
            s += groupNames[targetGroup];
            s += "\n";
            if (customTargetTowards)
            {
                s += "Values = ";
                s += FormatPrecise(targetVec3);
                s += "\n";
            }
        }
        else
        {
            s += "Scalar = ";
            s += scalarNames[targetScalar];
            s += "\n";
            if (customTargetTowards)
            {
                s += "Value = ";
                s += FormatPrecise(targetValue);
                s += "\n";
            }
        }

        s += "Towards = ";
        switch (targetTowards)
        {
        case -1:
            s += "Lower value is better.";
        break;
        case 0:
            s += "Custom.";
        break;
        case 1:
            s += "Higher value is better.";
        break;
        default:
            s += targetTowards;
        break;
        }

        s += "\n";
        s += CharRepeat(StringGetLastLineLength(s), '-');
        s += "\n\n";
    }

    {
        s += "Bounds: (actual values, so angles in radians and speeds in m/s)\n";
        uint maxScalarNameLength = 0;
        if (scalarIndices.IsEmpty())
        {
            const string NO_SCALARS = "None.";
            s += NO_SCALARS;
            s += "\n";
            maxScalarNameLength = NO_SCALARS.Length;
        }
        else
        {
            for (uint i = 0; i < scalarIndices.Length; i++)
            {
                const uint len = scalarNames[scalarIndices[i]].Length;
                if (maxScalarNameLength < len)
                    maxScalarNameLength = len;
            }

            for (uint i = 0; i < scalarIndices.Length; i++)
            {
                const ScalarKind kind = scalarIndices[i];
                const Scalar@ const scalar = scalars[kind];
                s += StringCopyPadRight(scalarNames[kind], maxScalarNameLength);
                s += " => ";

                if (scalar.lower)
                {
                    s += "Lower: ";
                    s += FormatPrecise(scalar.valueLower);
                }

                if (scalar.lower && scalar.upper)
                    s += ", ";

                if (scalar.upper)
                {
                    s += "Upper: ";
                    s += FormatPrecise(scalar.valueUpper);
                }

                s += "\n";
            }
        }

        s += CharRepeat(maxScalarNameLength, '-');
        s += "\n\n";
    }

    {
        s += "Conditions: (actual values)\n";
        uint maxConditionNameLength = 0;
        if (conditionIndices.IsEmpty())
        {
            const string NO_CONDITIONS = "None.";
            s += NO_CONDITIONS;
            s += "\n";
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
                const Condition@ const condition = conditions[kind];
                s += StringCopyPadRight(conditionNames[kind], maxConditionNameLength);
                s += " => ";
                switch (kind)
                {
                case ConditionKind::WHEEL_CONTACTS:
                case ConditionKind::GEAR:
                case ConditionKind::REAR_GEAR:
                    if (condition.valueMin == condition.valueMax)
                    {
                        s += condition.valueMin;
                    }
                    else
                    {
                        s += "[";
                        s += condition.valueMin;
                        s += ", ";
                        s += condition.valueMax;
                        s += "]";
                    }
                break;
                default:
                    s += condition.value;
                break;
                }
                s += "\n";
            }
        }

        s += CharRepeat(maxConditionNameLength, '-');
        s += "\n\n";
    }

    print(s);
}

void OnSimulationEnd(SimulationManager@, SimulationResult)
{
    valid = false;
    met = false;

    scalarIndices.Clear();
    unmetScalarIndices.Clear();
    unmetScalarTimes.Clear();

    conditionIndices.Clear();
    unmetConditionIndices.Clear();
    unmetConditionTimes.Clear();
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
            met = true; // prevent memory leak in unmet* arrays

            string s;
            Severity severity;
            if (valid)
            {
                if (isTargetGrouped)
                    s += groupNames[targetGroup];
                else
                    s += scalarNames[targetScalar];

                s += " | ";

                if (isTargetGrouped)
                    s += FormatVec3ByTargetGroup(best3, 6);
                else
                    s += FormatValueByScalar(targetScalar, best, 6);

                s += " | Time: ";
                s += Time::Format(impTime);

                if (customTargetTowards)
                {
                    s += " | Diff: ";
                    s += FormatValueByTarget(diffBest);
                }

                const uint iterations = info.Iterations;
                if (iterations == 0)
                {
                    severity = Severity::Info;
                }
                else
                {
                    s += " | Iterations: ";
                    s += iterations;
                    severity = Severity::Success;
                }
            }
            else
            {
                s += "Base Run did not suffice...\n";

				const uint unmetConditionLength = unmetConditionIndices.Length;
                if (unmetConditionLength != 0)
                {
                    s += "\nUnmet conditions:\n";
                    for (uint i = 0; i < unmetConditionLength; i++)
                    {
                        s += unmetConditionTimes[i];
                        s += " ";
                        s += conditionNames[unmetConditionIndices[i]];
                        s += "\n";
                    }
                }

				const uint unmetScalarLength = unmetScalarIndices.Length;
                if (unmetScalarLength != 0)
                {
                    s += "\nUnmet scalars:\n";
                    for (uint i = 0; i < unmetScalarLength; i++)
                    {
                        s += unmetScalarTimes[i];
                        s += " ";
                        s += scalarNames[unmetScalarIndices[i]];
                        s += "\n";
                    }
                }

                severity = Severity::Warning;
            }

            print(s, severity);
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
    return time >= evalFrom && time <= evalTo;
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

    const ms time = simManager.RaceTime;
    for (uint i = 0; i < conditionIndices.Length; i++)
    {
        const ConditionKind kind = conditionIndices[i];
        const Condition@ const condition = conditions[kind];
        bool ok;
        switch (kind)
        {
        case ConditionKind::MIN_REAL_SPEED:
            ok = velocity >= condition.value;
        break;
        case ConditionKind::FREEWHEELING:
            ok = condition.MatchBool(svc.IsFreeWheeling);
        break;
        case ConditionKind::SLIDING:
            ok = condition.MatchBool(svc.IsSliding);
        break;
        case ConditionKind::WHEEL_TOUCHING:
            ok = condition.MatchBool(svc.HasAnyLateralContact);
        break;
        case ConditionKind::WHEEL_CONTACTS:
            {
                int contacts = 0;
                const auto@ const wheels = simManager.Wheels;
                for (uint w = 0; w < 4; w++)
                {
                    if (wheels[w].RTState.HasGroundContact)
                        contacts++;
                }

                ok = condition.CompareInt(contacts);
            }
        break;
        case ConditionKind::CHECKPOINTS:
            ok = condition.MatchUInt(playerInfo.CurCheckpointCount);
        break;
        case ConditionKind::RPM:
        	ok = condition.CompareDouble(engine.ActualRPM);
    	break;
        case ConditionKind::GEAR:
            ok = condition.CompareInt(engine.Gear);
        break;
        case ConditionKind::REAR_GEAR:
            ok = condition.CompareInt(engine.RearGear);
        break;
        case ConditionKind::GLITCHING:
            {
                const double positionalDifference = Math::Distance(
                    previousState.Location.Position,
                    currentState.Location.Position);
                const bool isGlitching = positionalDifference > 0.1 && velocity / positionalDifference < 50.0;
                ok = condition.MatchBool(isGlitching);
            }
        break;
        default:
            print("Corrupted condition index: " + kind, Severity::Error);
            ok = false;
        break;
        }

        if (!ok)
        {
            if (!met)
            {
                unmetConditionIndices.Add(kind);
                unmetConditionTimes.Add(time);
            }
            return false;
        }
    }

    for (uint i = 0; i < scalarIndices.Length; i++)
    {
        const ScalarKind kind = scalarIndices[i];
        const double value = GetScalarValue(simManager, kind);

        const Scalar@ const scalar = scalars[kind];
        if (scalar.lower && value < scalar.valueLower || scalar.upper && value > scalar.valueUpper)
        {
            if (!met)
            {
                unmetScalarIndices.Add(kind);
                unmetScalarTimes.Add(time);
            }
            return false;
        }
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

double GetScalarValue(SimulationManager@ simManager, const ScalarKind kind)
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
    case ScalarKind::POSITION_X:
        value = position.x;
    break;
    case ScalarKind::POSITION_Y:
        value = position.y;
    break;
    case ScalarKind::POSITION_Z:
        value = position.z;
    break;
    case ScalarKind::ROTATION_YAW:
        rotation.GetYawPitchRoll(value, void, void);
    break;
    case ScalarKind::ROTATION_PITCH:
        rotation.GetYawPitchRoll(void, value, void);
    break;
    case ScalarKind::ROTATION_ROLL:
        rotation.GetYawPitchRoll(void, void, value);
    break;
    case ScalarKind::SPEED_GLOBAL_X:
        value = globalSpeed.x;
    break;
    case ScalarKind::SPEED_GLOBAL_Y:
        value = globalSpeed.y;
    break;
    case ScalarKind::SPEED_GLOBAL_Z:
        value = globalSpeed.z;
    break;
    case ScalarKind::SPEED_LOCAL_X:
        value = localSpeed.x;
    break;
    case ScalarKind::SPEED_LOCAL_Y:
        value = localSpeed.y;
    break;
    case ScalarKind::SPEED_LOCAL_Z:
        value = localSpeed.z;
    break;
    case ScalarKind::WHEEL_FL_X:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).x;
    break;
    case ScalarKind::WHEEL_FL_Y:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).y;
    break;
    case ScalarKind::WHEEL_FL_Z:
        value = AddOffsetToLocation(wheels.FrontLeft,  location).z;
    break;
    case ScalarKind::WHEEL_FR_X:
        value = AddOffsetToLocation(wheels.FrontRight, location).x;
    break;
    case ScalarKind::WHEEL_FR_Y:
        value = AddOffsetToLocation(wheels.FrontRight, location).y;
    break;
    case ScalarKind::WHEEL_FR_Z:
        value = AddOffsetToLocation(wheels.FrontRight, location).z;
    break;
    case ScalarKind::WHEEL_BR_X:
        value = AddOffsetToLocation(wheels.BackRight,  location).x;
    break;
    case ScalarKind::WHEEL_BR_Y:
        value = AddOffsetToLocation(wheels.BackRight,  location).y;
    break;
    case ScalarKind::WHEEL_BR_Z:
        value = AddOffsetToLocation(wheels.BackRight,  location).z;
    break;
    case ScalarKind::WHEEL_BL_X:
        value = AddOffsetToLocation(wheels.BackLeft,   location).x;
    break;
    case ScalarKind::WHEEL_BL_Y:
        value = AddOffsetToLocation(wheels.BackLeft,   location).y;
    break;
    case ScalarKind::WHEEL_BL_Z:
        value = AddOffsetToLocation(wheels.BackLeft,   location).z;
    break;
    default:
        print("Corrupted scalar index: " + kind, Severity::Error);
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
