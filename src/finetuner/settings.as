const string VAR = ID + "_";

const string VAR_EVAL_FROM = VAR + "eval_from";
const string VAR_EVAL_TO   = VAR + "eval_to";

const string VAR_TARGET_GROUPED = VAR + "target_grouped";
const string VAR_TARGET_SCALAR  = VAR + "target_scalar";
const string VAR_TARGET_GROUP   = VAR + "target_group";
const string VAR_TARGET_TOWARDS = VAR + "target_towards";

const string VAR_TARGET_VALUE         = VAR + "target_value";
const string VAR_TARGET_VALUE_DISPLAY = VAR + "target_value_display";

const string VAR_TARGET_VEC3         = VAR + "target_vec3";
const string VAR_TARGET_VEC3_DISPLAY = VAR + "target_vec3_display";

const string VAR_PRINT_BY_COMPONENT = VAR + "print_by_component";

const string VAR_COMMON_GROUPS     = VAR + "common_groups";
const string VAR_COMMON_SCALARS    = VAR + "common_scalars";
const string VAR_COMMON_CONDITIONS = VAR + "common_conditions";

ms evalFrom;
ms evalTo;

bool isTargetGrouped;
GroupKind targetGroup;
ScalarKind targetScalar;
int targetTowards;

double targetValue;
float targetValueDisplay;

vec3 targetVec3;
vec3 targetVec3Display;

bool printByComponent;

void RegisterSettings()
{
    RegisterVariable(VAR_EVAL_FROM, 0);
    RegisterVariable(VAR_EVAL_TO,   0);

    RegisterVariable(VAR_TARGET_GROUPED, true);
    RegisterVariable(VAR_TARGET_SCALAR,  0);
    RegisterVariable(VAR_TARGET_GROUP,   0);
    RegisterVariable(VAR_TARGET_TOWARDS, 0);

    RegisterVariable(VAR_TARGET_VALUE,           0);
    RegisterVariable(VAR_TARGET_VALUE_DISPLAY,   0);

    RegisterVariable(VAR_TARGET_VEC3,         vec3().ToString());
    RegisterVariable(VAR_TARGET_VEC3_DISPLAY, vec3().ToString());

    RegisterVariable(VAR_PRINT_BY_COMPONENT, false);

    RegisterVariable(VAR_COMMON_GROUPS,     "");
    RegisterVariable(VAR_COMMON_SCALARS,    "");
    RegisterVariable(VAR_COMMON_CONDITIONS, "");

    evalFrom = GetConVarTime(VAR_EVAL_FROM);
    evalTo   = GetConVarTime(VAR_EVAL_TO);

    isTargetGrouped = GetConVarBool(VAR_TARGET_GROUPED);
    targetScalar    = ScalarKind(GetVariableDouble(VAR_TARGET_SCALAR));
    targetGroup     = GroupKind(GetVariableDouble(VAR_TARGET_GROUP));
    targetTowards   = GetConVarInt(VAR_TARGET_TOWARDS);

    targetValue        = GetConVarDouble(VAR_TARGET_VALUE);
    targetValueDisplay = GetConVarDouble(VAR_TARGET_VALUE_DISPLAY);

    targetVec3        = GetConVarVec3(VAR_TARGET_VEC3);
    targetVec3Display = GetConVarVec3(VAR_TARGET_VEC3_DISPLAY);

    printByComponent = GetConVarBool(VAR_PRINT_BY_COMPONENT);

    DeserializeGroups(    GetConVarString(VAR_COMMON_GROUPS));
    DeserializeScalars(   GetConVarString(VAR_COMMON_SCALARS));
    DeserializeConditions(GetConVarString(VAR_COMMON_CONDITIONS));
}

void SaveSettings()
{
    SaveGroups();
    SaveScalars();
    SaveConditions();
}

void SaveGroups()
{
    SetVariable(VAR_COMMON_GROUPS, SerializeGroups());
}

void SaveScalars()
{
    SetVariable(VAR_COMMON_SCALARS, SerializeScalars());
}

void SaveConditions()
{
    SetVariable(VAR_COMMON_CONDITIONS, SerializeConditions());
}

const string HIDDEN_EDITOR_LABEL = "<Hide>";

int triggerPosEditorID = -1;
int triggerPosEditorIndex = -1;

GroupKind groupInEditor = GroupKind::NONE;
ConditionKind conditionInEditor = ConditionKind::NONE;

void RenderSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate From", VAR_EVAL_FROM);
    evalTo   = UI::InputTimeVar("Evaluate To",   VAR_EVAL_TO);
    if (evalTo < evalFrom)
        SetVariable(VAR_EVAL_TO, evalTo = evalFrom);

    isTargetGrouped = UI::CheckboxVar("Grouped Target?", VAR_TARGET_GROUPED);
    if (isTargetGrouped)
    {
        ComboHelper("Target (Group):", groupNames, targetGroup,
            function(index)
            {
                targetGroup = GroupKind(index);
                SetVariable(VAR_TARGET_GROUP, targetGroup);
            }
        );

        if (targetGroup == GroupKind::ROTATION)
            UI::TextDimmed("WARNING: using grouped rotation is not recommended.");
    }
    else
    {
        ComboHelper("Target (Scalar):", scalarNames, targetScalar,
            function(index)
            {
                targetScalar = ScalarKind(index);
                SetVariable(VAR_TARGET_SCALAR, targetScalar);
            }
        );
    }

    targetTowards = UI::SliderIntVar("Target Towards", VAR_TARGET_TOWARDS, -1, 1);

    {
        bool disableTarget;
        string targetTowardsMessage;
        switch (targetTowards)
        {
        case -1:
            disableTarget = true;
            targetTowardsMessage = "Lower value is better.";
            break;
        case 1:
            disableTarget = true;
            targetTowardsMessage = "Higher value is better.";
            break;
        default:
            disableTarget = false;
            targetTowardsMessage = "Custom:";
            break;
        }
        UI::TextDimmed(targetTowardsMessage);

        UI::BeginDisabled(disableTarget);
        if (isTargetGrouped)
        {
            if (UI::DragFloat3Var("Target Values", VAR_TARGET_VEC3_DISPLAY))
            {
                targetVec3Display = GetConVarVec3(VAR_TARGET_VEC3_DISPLAY);
                targetVec3 = ConvertDisplayToValue3(targetGroup, targetVec3Display);
                SetVariable(VAR_TARGET_VEC3, targetVec3);
            }
        }
        else
        {
            targetValueDisplay = UI::InputFloatVar("Target Value", VAR_TARGET_VALUE_DISPLAY);
            targetValue = ConvertDisplayToValue(targetScalar, targetValueDisplay);
            SetVariable(VAR_TARGET_VALUE, targetValue);
        }
        UI::EndDisabled();
    }

    if (isTargetGrouped)
    {
        printByComponent = UI::CheckboxVar("Print Group values by component?", VAR_PRINT_BY_COMPONENT);
        TooltipOnHover("Whether the values of the target group are to be printed by component (e.g. x y z), or as one value.");

        if (targetGroup == GroupKind::POSITION)
        {
            vec3 cameraPosition;
            if (CameraPosOnClick("Use Cam Position", cameraPosition))
                SetTargetVec3(cameraPosition);
            UI::SameLine();
            vec3 carPosition;
            if (CarPosOnClick("Use Car Position", carPosition))
                SetTargetVec3(carPosition);
        }
    }

    UI::Separator();
    UI::Separator();

    {
        const bool isHiddenGroupInEditor = groupInEditor == GroupKind::NONE;
        const string currentGroup =
            isHiddenGroupInEditor ? HIDDEN_EDITOR_LABEL : groupNames[groupInEditor];
        if (UI::BeginCombo("Group Editor", currentGroup))
        {
            UI::PushID("group_editor");

            if (UI::Selectable(HIDDEN_EDITOR_LABEL, isHiddenGroupInEditor))
                groupInEditor = GroupKind::NONE;

            for (uint i = 0; i < GroupKind::COUNT; i++)
            {
                const GroupKind kind = GroupKind(i);
                UI::PushID("" + i);

                Group@ const group = groups[kind];
                group.active = UI::Checkbox("##active", group.active);
                UI::SameLine();
                if (UI::Selectable(groupNames[kind], groupInEditor == kind))
                    groupInEditor = kind;

                UI::PopID();
            }

            UI::PopID();
            UI::EndCombo();
        }
    }

    if (groupInEditor != GroupKind::NONE)
    {
        UI::PushID("group_in_editor_" + groupInEditor);

        Group@ const group = groups[groupInEditor];
        group.active = UI::Checkbox("Active", group.active);

        const bool resetAll = UI::Button("Reset All");
        UI::SameLine();
        const bool toggleAll = UI::Button("Toggle All");
        UI::SameLine();
        const bool activateAll = UI::Button("Activate All");

        const auto@ const scalarsToRender = GroupKindToScalarKinds(groupInEditor);
        if (groupInEditor == GroupKind::POSITION)
        {
            TriggerCombo(triggerPosEditorID, triggerPosEditorIndex);

            Trigger3D trigger;
            if (GetTriggerOrReset(triggerPosEditorID, triggerPosEditorIndex, trigger))
            {
                const vec3 position = trigger.Position;
                const vec3 size = trigger.Size;
                for (uint i = 0; i < 3; i++)
                {
                    Scalar@ const scalar = scalars[scalarsToRender[i]];
                    scalar.valueLower = position[i];
                    scalar.valueUpper = position[i] + size[i];
                    scalar.displayLower = scalar.valueLower;
                    scalar.displayUpper = scalar.valueUpper;
                }
            }

            vec3 cameraPosition;
            if (CameraPosOnClick("Use Cam Position", cameraPosition))
            {
                ResetTriggerID(triggerPosEditorID, triggerPosEditorIndex);
                BoundScalarsByVec3(scalarsToRender, cameraPosition);
            }
            UI::SameLine();
            vec3 carPosition;
            if (CarPosOnClick("Use Car Position", carPosition))
            {
                ResetTriggerID(triggerPosEditorID, triggerPosEditorIndex);
                BoundScalarsByVec3(scalarsToRender, carPosition);
            }
        }

        for (uint i = 0; i < scalarsToRender.Length; i++)
        {
            const ScalarKind scalarKind = scalarsToRender[i];
            UI::PushID("" + i);

            UI::Separator();

            Scalar@ const scalar = scalars[scalarKind];
            if (UI::Button("Reset") || resetAll)
                scalar.Reset();
            UI::SameLine();
            UI::TextWrapped("Scalar: " + scalarNames[scalarKind]);

            scalar.lower = UI::Checkbox("Lower Bound", scalar.lower) || activateAll;
            UI::SameLine();
            scalar.upper = UI::Checkbox("Upper Bound", scalar.upper) || activateAll;

            if (toggleAll)
            {
                scalar.lower = !scalar.lower;
                scalar.upper = !scalar.upper;
            }

            UI::PushItemWidth(192);
            UI::BeginDisabled(!scalar.lower);

            scalar.displayLower = UI::InputFloat("##lower", scalar.displayLower);
            if (scalar.lower)
                scalar.valueLower = ConvertDisplayToValue(groupInEditor, scalar.displayLower);

            UI::EndDisabled();
            UI::SameLine();
            UI::BeginDisabled(!scalar.upper);

            scalar.displayUpper = UI::InputFloat("##upper", scalar.displayUpper);
            if (scalar.upper)
                scalar.valueUpper = ConvertDisplayToValue(groupInEditor, scalar.displayUpper);

            UI::EndDisabled();
            UI::PopItemWidth();

            UI::PopID();
        }

        UI::PopID();
    }

    UI::Separator();
    UI::Separator();

    {
        const bool isHiddenConditionInEditor = conditionInEditor == ConditionKind::NONE;
        const string currentCondition =
            isHiddenConditionInEditor ? HIDDEN_EDITOR_LABEL : conditionNames[conditionInEditor];
        if (UI::BeginCombo("Condition Editor", currentCondition))
        {
            UI::PushID("condition_editor");

            if (UI::Selectable(HIDDEN_EDITOR_LABEL, isHiddenConditionInEditor))
                conditionInEditor = ConditionKind::NONE;

            for (uint i = 0; i < ConditionKind::COUNT; i++)
            {
                const ConditionKind kind = ConditionKind(i);
                UI::PushID("" + i);

                Condition@ const condition = conditions[kind];
                condition.active = UI::Checkbox("##active", condition.active);
                UI::SameLine();
                if (UI::Selectable(conditionNames[kind], conditionInEditor == kind))
                    conditionInEditor = kind;

                UI::PopID();
            }

            UI::PopID();
            UI::EndCombo();
        }
    }

    if (conditionInEditor != ConditionKind::NONE)
    {
        UI::PushID("condition_in_editor_" + conditionInEditor);

        Condition@ const condition = conditions[conditionInEditor];
        condition.active = UI::Checkbox("Active", condition.active);

        if (UI::Button("Reset"))
            condition.Reset();

        switch (conditionInEditor)
        {
        case ConditionKind::MIN_REAL_SPEED:
            condition.display = UI::InputFloat("##min_real_speed", condition.display);
            UI::TextDimmed(
                "The car MUST have a real speed of at least " +
                condition.display +
                " km/h in the eval timeframe.");

            condition.value = condition.display / 3.6;
            break;
        case ConditionKind::FREEWHEELING:
            RenderConditionBool(condition, "##freewheeling", "be free-wheeled");
            break;
        case ConditionKind::SLIDING:
            RenderConditionBool(condition, "##sliding", "be sliding");
            break;
        case ConditionKind::WHEEL_TOUCHING:
            RenderConditionBool(condition, "##wheel_touching", "have wheel(s) crashing into a wall");
            break;
        case ConditionKind::WHEEL_CONTACTS:
            RenderConditionSliderInt(condition, "##wheel_contacts", 0, 4, "wheels contacting the ground");
            break;
        case ConditionKind::CHECKPOINTS:
            condition.display = UI::InputInt("##checkpoints", int(condition.display));
            UI::TextDimmed(
                "The car MUST have collected exactly " +
                condition.display +
                " checkpoints in the eval timeframe.");

            condition.value = condition.display;
            break;
        case ConditionKind::GEAR:
            RenderConditionSliderInt(condition, "##gear", 0, 5, "gears");
            break;
        case ConditionKind::REAR_GEAR:
            RenderConditionSliderInt(condition, "##rear_gear", 0, 1, "rear gears");
            break;
        case ConditionKind::GLITCHING:
            RenderConditionBool(condition, "##glitching", "be glitching");
            break;
        default:
            UI::TextWrapped("Corrupted condition index: " + conditionInEditor);
            break;
        }

        UI::PopID();
    }

    SaveSettings();
}

bool CameraPosOnClick(const string &in label, vec3 &out position)
{
    if (UI::Button(label))
    {
        const auto@ const camera = GetCurrentCamera();
        if (camera !is null)
        {
            position = camera.Location.Position;
            return true;
        }
    }

    position = vec3();
    return false;
}

bool CarPosOnClick(const string &in label, vec3 &out position)
{
    if (UI::Button(label))
    {
        const auto@ const dyna = GetSimulationManager().Dyna;
        if (dyna !is null)
        {
            position = dyna.RefStateCurrent.Location.Position;
            return true;
        }
    }

    position = vec3();
    return false;
}

void SetTargetVec3(const vec3 &in value)
{
    SetVariable(VAR_TARGET_VEC3, targetVec3 = value);
    SetVariable(VAR_TARGET_VEC3_DISPLAY, targetVec3Display = value);
}

void TriggerCombo(int& id, int& index)
{
    if (UI::BeginCombo("Triggers", (index + 1) + "."))
    {
        if (UI::Selectable("0.", id == -1))
            ResetTriggerID(id, index);

        const auto@ const ids = GetTriggerIds();
        for (uint i = 0; i < ids.Length; i++)
        {
            const int triggerID = ids[i];
            const Trigger3D trigger = GetTrigger(triggerID);
            if (UI::Selectable((i + 1) + ". " + TriggerToString(trigger), id == triggerID))
            {
                id = triggerID;
                index = i;
            }
        }

        UI::EndCombo();
    }
}

string TriggerToString(const Trigger3D &in trigger)
{
    return "[ " + trigger.Position.ToString() + " | " + trigger.Size.ToString() + " ]";
}

bool GetTriggerOrReset(int& id, int& index, Trigger3D &out trigger)
{
    trigger = GetTrigger(id);
    if (trigger)
        return true;

    ResetTriggerID(id, index);
    return false;
}

void ResetTriggerID(int& id, int& index)
{
    id = -1;
    index = -1;
}

void BoundScalarsByVec3(const array<ScalarKind>@ scalarKinds, const vec3 &in v, const double offset = 2)
{
    if (scalarKinds.Length != 3)
    {
        UI::TextWrapped("ERROR: cannot bound scalars by vec3.");
        return;
    }

    for (uint i = 0; i < 3; i++)
    {
        const ScalarKind kind = scalarKinds[i];
        Scalar@ const scalar = scalars[kind];
        scalar.lower = true;
        scalar.upper = true;
        scalar.valueLower = v[i] - offset;
        scalar.valueUpper = v[i] + offset;
        scalar.displayLower = ConvertValueToDisplay(kind, scalar.valueLower);
        scalar.displayUpper = ConvertValueToDisplay(kind, scalar.valueUpper);
    }
}

void RenderConditionBool(Condition@ condition, const string &in id, const string &in what)
{
    const bool tempValue = UI::Checkbox(id, condition.display != 0);
    condition.display = tempValue ? 1 : 0;
    UI::TextDimmed("The car MUST" + (tempValue ? " " : " NOT ") + what + " in the eval timeframe.");

    condition.value = condition.display;
}

void RenderConditionSliderInt(Condition@ condition, const string &in id, const int min, const int max, const string &in what)
{
    const int sliderMin = UI::SliderInt(id + "_min", int(condition.displayMin), min, max);
    const int sliderMax = UI::SliderInt(id + "_max", int(condition.displayMax), min, max);
    condition.displayMin = Math::Min(sliderMin, sliderMax);
    condition.displayMax = Math::Max(sliderMin, sliderMax);

    string msg;
    if (condition.displayMin == condition.displayMax)
        msg = "exactly " + condition.displayMin;
    else
        msg = "between " + condition.displayMin + " and " + condition.displayMax;

    UI::TextDimmed("The car MUST have " + msg + " " + what + " in the eval timeframe.");

    condition.valueMin = condition.displayMin;
    condition.valueMax = condition.displayMax;
}
