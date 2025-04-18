const string VAR = ID + "_";

const string VAR_EVAL_FROM = VAR + "eval_from";
const string VAR_EVAL_TO   = VAR + "eval_to";

const string VAR_TARGET_GROUPED = VAR + "target_grouped";
const string VAR_TARGET_SCALAR  = VAR + "target_scalar";
const string VAR_TARGET_GROUP   = VAR + "target_group";
const string VAR_TARGET_VALUE   = VAR + "target_value";
const string VAR_TARGET_3VALUES = VAR + "target_3values";
const string VAR_TARGET_TOWARDS = VAR + "target_towards";

const string VAR_PRINT_BY_COMPONENT = VAR + "print_by_component";

const string VAR_COMMON_GROUPS     = VAR + "common_groups";
const string VAR_COMMON_SCALARS    = VAR + "common_scalars";
const string VAR_COMMON_CONDITIONS = VAR + "common_conditions";

const string VAR_DEPRECATED_MODES = VAR + "common_modes";

ms evalFrom;
ms evalTo;

bool isTargetGrouped;
ScalarKind targetScalar;
GroupKind targetGroup;
int targetTowards;
double targetValue;
vec3 target3Values;

bool printByComponent;

void RegisterSettings()
{
    RegisterVariable(VAR_EVAL_FROM, 0);
    RegisterVariable(VAR_EVAL_TO,   0);

    RegisterVariable(VAR_TARGET_GROUPED, true);
    RegisterVariable(VAR_TARGET_SCALAR,  0);
    RegisterVariable(VAR_TARGET_GROUP,   0);
    RegisterVariable(VAR_TARGET_TOWARDS, 0);
    RegisterVariable(VAR_TARGET_VALUE,   0);
    RegisterVariable(VAR_TARGET_3VALUES, vec3().ToString());

    RegisterVariable(VAR_PRINT_BY_COMPONENT, false);

    RegisterVariable(VAR_COMMON_GROUPS,     "");
    RegisterVariable(VAR_COMMON_SCALARS,    "");
    RegisterVariable(VAR_COMMON_CONDITIONS, "");

    RegisterVariable(VAR_DEPRECATED_MODES, "");

    evalFrom = GetConVarTime(VAR_EVAL_FROM);
    evalTo   = GetConVarTime(VAR_EVAL_TO);

    isTargetGrouped = GetConVarBool(VAR_TARGET_GROUPED);
    targetScalar    = ScalarKind(GetVariableDouble(VAR_TARGET_SCALAR));
    targetGroup     = GroupKind(GetVariableDouble(VAR_TARGET_GROUP));
    targetTowards   = GetConVarInt(VAR_TARGET_TOWARDS);
    targetValue     = GetConVarDouble(VAR_TARGET_VALUE);
    target3Values   = GetConVarVec3(VAR_TARGET_3VALUES);

    printByComponent = GetConVarBool(VAR_PRINT_BY_COMPONENT);

    const string deprecatedModes = GetConVarString(VAR_DEPRECATED_MODES);
    if (!deprecatedModes.IsEmpty())
    {
        SetVariable(VAR_COMMON_SCALARS, deprecatedModes);
        SetVariable(VAR_DEPRECATED_MODES, "");
    }

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
        ComboHelper("Target (Group):", groupNames, targetGroup,
            function(index)
            {
                targetGroup = GroupKind(index);
                SetVariable(VAR_TARGET_GROUP, targetGroup);
            }
        );
    else
        ComboHelper("Target (Scalar):", scalarNames, targetScalar,
            function(index)
            {
                targetScalar = ScalarKind(index);
                SetVariable(VAR_TARGET_SCALAR, targetScalar);
            }
        );

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
            if (UI::DragFloat3Var("Target Values", VAR_TARGET_3VALUES))
                target3Values = GetConVarVec3(VAR_TARGET_3VALUES);
        }
        else
        {
            targetValue = UI::InputFloatVar("Target Value", VAR_TARGET_VALUE);
        }
        UI::EndDisabled();
    }

    if (isTargetGrouped)
    {
        printByComponent = UI::CheckboxVar("Print Group values by component?", VAR_PRINT_BY_COMPONENT);
        TooltipOnHover("Whether the values of the target group are to be printed by component (e.g. x y z), or as one value.");
    }

    UI::Separator();

    {
        const bool isHiddenGroupInEditor = groupInEditor == GroupKind::NONE;
        const string currentGroup =
            isHiddenGroupInEditor ?
                HIDDEN_EDITOR_LABEL :
                groupNames[groupInEditor];
        if (UI::BeginCombo("Group Editor", currentGroup))
        {
            UI::PushID("group_editor");

            if (UI::Selectable(HIDDEN_EDITOR_LABEL, isHiddenGroupInEditor))
                groupInEditor = GroupKind::NONE;

            for (uint i = 0; i < GroupKind::COUNT; i++)
            {
                UI::PushID("" + i);

                const GroupKind kind = GroupKind(i);
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

    {
        array<ScalarKind> scalarsToRender;
        if (GroupKindToScalarKinds(groupInEditor, scalarsToRender))
        {
            UI::PushID("group_in_editor_" + groupInEditor);

            const bool resetAll = UI::Button("Reset All");
            UI::SameLine();
            UI::TextWrapped(
                "Group: " + groupNames[groupInEditor] +
                " = " + (groups[groupInEditor].active ? "ON" : "OFF"));

            for (uint i = 0; i < scalarsToRender.Length; i++)
            {
                UI::PushID("" + i);

                UI::Separator();

                const ScalarKind scalarKind = scalarsToRender[i];
                Scalar@ const scalar = scalars[scalarKind];
                if (UI::Button("Reset") || resetAll)
                    scalar.Reset();
                UI::SameLine();
                UI::TextWrapped("Scalar: " + scalarNames[scalarKind]);

                scalar.lower = UI::Checkbox("Lower Bound", scalar.lower);
                UI::SameLine();
                scalar.upper = UI::Checkbox("Upper Bound", scalar.upper);

                GroupKind groupKind;
                // discard
                ScalarKindToGroupKind(scalarKind, groupKind);

                UI::PushItemWidth(192);

                UI::BeginDisabled(!scalar.lower);

                scalar.lowerDisplay = UI::InputFloat("##lower", scalar.lowerDisplay);
                if (scalar.lower)
                    scalar.lowerValue = ConvertDisplayToValue(groupKind, scalar.lowerDisplay);

                UI::EndDisabled();
                UI::SameLine();
                UI::BeginDisabled(!scalar.upper);

                scalar.upperDisplay = UI::InputFloat("##upper", scalar.upperDisplay);
                if (scalar.upper)
                    scalar.upperValue = ConvertDisplayToValue(groupKind, scalar.upperDisplay);

                UI::EndDisabled();

                UI::PopItemWidth();

                UI::PopID();
            }

            UI::PopID();
        }
    }

    UI::Separator();

    {
        const bool isHiddenConditionInEditor = conditionInEditor == ConditionKind::NONE;
        const string currentCondition =
            isHiddenConditionInEditor ?
                HIDDEN_EDITOR_LABEL :
                conditionNames[conditionInEditor];
        if (UI::BeginCombo("Condition Editor", currentCondition))
        {
            UI::PushID("condition_editor");

            if (UI::Selectable(HIDDEN_EDITOR_LABEL, isHiddenConditionInEditor))
                conditionInEditor = ConditionKind::NONE;

            for (uint i = 0; i < ConditionKind::COUNT; i++)
            {
                UI::PushID("" + i);

                const ConditionKind kind = ConditionKind(i);
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
        if (UI::Button("Reset"))
            condition.Reset();
        UI::SameLine();
        UI::TextWrapped(
            "Condition: " + conditionNames[conditionInEditor] +
            " = " + (condition.active ? "ON" : "OFF"));

        switch (conditionInEditor)
        {
        case ConditionKind::MIN_REAL_SPEED:
            {
                const float tempValue = UI::InputFloat(
                    "##min_real_speed", condition.display);
                condition.display = tempValue;

                condition.value = condition.display / 3.6;
                UI::TextDimmed(
                    "The car MUST have a real speed of at least " +
                    tempValue +
                    " km/h in the eval timeframe.");
            }
            break;
        case ConditionKind::FREEWHEELING:
            RenderConditionBool(condition, "##freewheeling", "be free-wheeled in the eval timeframe.");
            break;
        case ConditionKind::SLIDING:
            RenderConditionBool(condition, "##sliding", "be sliding in the eval timeframe.");
            break;
        case ConditionKind::WHEEL_TOUCHING:
            RenderConditionBool(condition, "##wheel_touching", "have wheel(s) crashing into a wall in the eval timeframe.");
            break;
        case ConditionKind::WHEEL_CONTACTS:
            {
                const uint tempValue = UI::SliderInt(
                    "##wheel_contacts", uint(condition.display), 0, 4);
                condition.display = tempValue;

                condition.value = condition.display;
                UI::TextDimmed(
                    "The car MUST have at least " +
                    tempValue +
                    " wheels contacting the ground in the eval timeframe.");
            }
            break;
        case ConditionKind::CHECKPOINTS:
            {
                const uint tempValue = UI::InputInt(
                    "##checkpoints", uint(condition.display));
                condition.display = tempValue;

                condition.value = condition.display;
                UI::TextDimmed(
                    "The car MUST have collected exactly " +
                    tempValue +
                    " checkpoints in the eval timeframe.");
            }
            break;
        case ConditionKind::GEAR:
            {
                const int tempValue = UI::SliderInt(
                    "##gear", int(condition.display), 0, 5);
                condition.display = tempValue;

                condition.value = condition.display;
                UI::TextDimmed(
                    "The car MUST be in exactly gear " +
                    tempValue +
                    " in the eval timeframe.");
            }
            break;
        case ConditionKind::REAR_GEAR:
            {
                const int tempValue = UI::SliderInt(
                    "##rear_gear", int(condition.display), 0, 1);
                condition.display = tempValue;

                condition.value = condition.display;
                UI::TextDimmed(
                    "The car MUST be in exactly rear gear " +
                    tempValue +
                    " in the eval timeframe.");
            }
            break;
        case ConditionKind::GLITCHING:
            RenderConditionBool(condition, "##glitching", "be glitching in the eval timeframe.");
            break;
        default:
            UI::TextWrapped("Corrupted condition index: " + conditionInEditor);
            break;
        }

        UI::PopID();
    }

    SaveSettings();
}

void RenderConditionBool(Condition@ condition, const string &in id, const string &in what)
{
    const bool tempValue = UI::Checkbox(id, condition.display != 0);
    condition.display = tempValue ? 1 : 0;
    condition.value = condition.display;
    UI::TextDimmed("The car MUST" + (tempValue ? " " : " NOT ") + what);
}