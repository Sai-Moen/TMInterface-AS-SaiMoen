const string VAR = ID + "_";

const string VAR_EVAL_FROM = VAR + "eval_from";
const string VAR_EVAL_TO   = VAR + "eval_to";

const string VAR_TARGET_GROUPED = VAR + "target_grouped";
const string VAR_TARGET_MODE    = VAR + "target_mode";
const string VAR_TARGET_GROUP   = VAR + "target_group";
const string VAR_TARGET_VALUE   = VAR + "target_value";
const string VAR_TARGET_3VALUES = VAR + "target_3values";
const string VAR_TARGET_TOWARDS = VAR + "target_towards";

const string VAR_COMMON_GROUPS     = VAR + "common_groups";
const string VAR_COMMON_MODES      = VAR + "common_modes";
const string VAR_COMMON_CONDITIONS = VAR + "common_conditions";

ms evalFrom;
ms evalTo;

bool isTargetGrouped;
ModeKind targetMode;
GroupKind targetGroup;
int targetTowards;
double targetValue;
vec3 target3Values;

void RegisterSettings()
{
    RegisterVariable(VAR_EVAL_FROM, 0);
    RegisterVariable(VAR_EVAL_TO,   0);

    RegisterVariable(VAR_TARGET_GROUPED, true);
    RegisterVariable(VAR_TARGET_MODE,    0);
    RegisterVariable(VAR_TARGET_GROUP,   0);
    RegisterVariable(VAR_TARGET_TOWARDS, 0);
    RegisterVariable(VAR_TARGET_VALUE,   0);
    RegisterVariable(VAR_TARGET_3VALUES, vec3().ToString());

    RegisterVariable(VAR_COMMON_GROUPS,     "");
    RegisterVariable(VAR_COMMON_MODES,      "");
    RegisterVariable(VAR_COMMON_CONDITIONS, "");

    evalFrom = ms(GetVariableDouble(VAR_EVAL_FROM));
    evalTo   = ms(GetVariableDouble(VAR_EVAL_TO));

    isTargetGrouped = GetVariableBool(VAR_TARGET_GROUPED);
    targetMode      = ModeKind(GetVariableDouble(VAR_TARGET_MODE));
    targetGroup     = GroupKind(GetVariableDouble(VAR_TARGET_GROUP));
    targetTowards   = int(GetVariableDouble(VAR_TARGET_TOWARDS));
    targetValue     = GetVariableDouble(VAR_TARGET_VALUE);
    target3Values    = Text::ParseVec3(GetVariableString(VAR_TARGET_3VALUES));

    DeserializeGroups(    GetVariableString(VAR_COMMON_GROUPS));
    DeserializeModes(     GetVariableString(VAR_COMMON_MODES));
    DeserializeConditions(GetVariableString(VAR_COMMON_CONDITIONS));
}

void SaveSettings()
{
    SaveGroups();
    SaveModes();
    SaveConditions();
}

void SaveGroups()
{
    SetVariable(VAR_COMMON_GROUPS, SerializeGroups());
}

void SaveModes()
{
    SetVariable(VAR_COMMON_MODES, SerializeModes());
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
        ComboHelper("Target (Group):", targetGroup, groupNames,
            function(index)
            {
                targetGroup = GroupKind(index);
                SetVariable(VAR_TARGET_GROUP, targetGroup);
            }
        );
    else
        ComboHelper("Target (Mode):", targetMode, modeNames,
            function(index)
            {
                targetMode = ModeKind(index);
                SetVariable(VAR_TARGET_MODE, targetMode);
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
                target3Values = Text::ParseVec3(GetVariableString(VAR_TARGET_3VALUES));
        }
        else
        {
            targetValue = UI::InputFloatVar("Target Value", VAR_TARGET_VALUE);
        }
        UI::EndDisabled();
    }

    UI::Separator();

    {
        const bool isHiddenGroupInEditor = groupInEditor == GroupKind::NONE;
        const string currentGroup =
            isHiddenGroupInEditor ?
                HIDDEN_EDITOR_LABEL :
                groupNames[groupInEditor];
        if (UI::BeginCombo("Group/Mode Editor", currentGroup))
        {
            UI::PushID("group_editor");

            if (UI::Selectable(HIDDEN_EDITOR_LABEL, isHiddenGroupInEditor))
                groupInEditor = GroupKind::NONE;

            for (uint i = 0; i < GroupKind::COUNT; i++)
            {
                UI::PushID("" + i);

                groups[i].active = UI::Checkbox("##active", groups[i].active);
                UI::SameLine();
                const GroupKind kind = GroupKind(i);
                if (UI::Selectable(groupNames[kind], groupInEditor == kind))
                    groupInEditor = kind;

                UI::PopID();
            }

            UI::PopID();
            UI::EndCombo();
        }
    }

    {
        array<ModeKind> modesToRender;
        if (GroupKindToModeKinds(groupInEditor, modesToRender))
        {
            const bool resetAll = UI::Button("Reset All");
            UI::SameLine();
            UI::TextWrapped(
                "Group: " + groupNames[groupInEditor] +
                " = " + (groups[groupInEditor].active ? "ON" : "OFF"));

            UI::PushID("group_in_editor_" + groupInEditor);

            for (uint i = 0; i < modesToRender.Length; i++)
            {
                UI::Separator();

                UI::PushID("" + i);

                const ModeKind modeKind = modesToRender[i];
                // button has to be first or it will magically disappear for a frame if you Reset All
                if (UI::Button("Reset") || resetAll)
                    modes[modeKind].Reset();
                UI::SameLine();
                UI::TextWrapped("Mode: " + modeNames[modeKind]);

                modes[modeKind].lower = UI::Checkbox("Lower Bound", modes[modeKind].lower);
                UI::SameLine();
                modes[modeKind].upper = UI::Checkbox("Upper Bound", modes[modeKind].upper);

                GroupKind groupKind;
                // discard
                ModeKindToGroupKind(modeKind, groupKind);

                UI::PushItemWidth(192);

                UI::BeginDisabled(!modes[modeKind].lower);

                modes[modeKind].lowerDisplay = UI::InputFloat("##lower", modes[modeKind].lowerDisplay);
                if (modes[modeKind].lower)
                {
                    modes[modeKind].lowerValue =
                        ConvertDisplayToValue(groupKind, modes[modeKind].lowerDisplay);
                }

                UI::EndDisabled();
                UI::SameLine();
                UI::BeginDisabled(!modes[modeKind].upper);

                modes[modeKind].upperDisplay = UI::InputFloat("##upper", modes[modeKind].upperDisplay);
                if (modes[modeKind].upper)
                {
                    modes[modeKind].upperValue =
                        ConvertDisplayToValue(groupKind, modes[modeKind].upperDisplay);
                }

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

                conditions[i].active = UI::Checkbox("##active", conditions[i].active);
                UI::SameLine();
                const ConditionKind kind = ConditionKind(i);
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

        if (UI::Button("Reset"))
            conditions[conditionInEditor].Reset();
        UI::SameLine();
        UI::TextWrapped(
            "Condition: " + conditionNames[conditionInEditor] +
            " = " + (conditions[conditionInEditor].active ? "ON" : "OFF"));

        switch (conditionInEditor)
        {
        case ConditionKind::MIN_REAL_SPEED:
            {
                const float tempValue = UI::InputFloat(
                    "##min_real_speed", conditions[conditionInEditor].display);
                conditions[conditionInEditor].display = tempValue;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display / 3.6;
                UI::TextDimmed(
                    "The car MUST have a real speed of at least " +
                    tempValue +
                    " km/h in the eval timeframe.");
            }
            break;
        case ConditionKind::FREEWHEELING:
            {
                const bool tempValue = UI::Checkbox(
                    "##freewheeling", conditions[conditionInEditor].display != 0);
                conditions[conditionInEditor].display = tempValue ? 1 : 0;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display;
                UI::TextDimmed(
                    "The car MUST" +
                    (tempValue ? " " : " NOT ") +
                    "be free-wheeled in the eval timeframe.");
            }
            break;
        case ConditionKind::SLIDING:
            {
                const bool tempValue = UI::Checkbox(
                    "##sliding", conditions[conditionInEditor].display != 0);
                conditions[conditionInEditor].display = tempValue ? 1 : 0;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display;
                UI::TextDimmed(
                    "The car MUST" +
                    (tempValue ? " " : " NOT ") +
                    "be sliding in the eval timeframe.");
            }
            break;
        case ConditionKind::WHEEL_TOUCHING:
            {
                const bool tempValue = UI::Checkbox(
                    "##wheel_touching", conditions[conditionInEditor].display != 0);
                conditions[conditionInEditor].display = tempValue ? 1 : 0;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display;
                UI::TextDimmed(
                    "The car MUST" +
                    (tempValue ? " " : " NOT ") +
                    "have wheel(s) crashing into a wall in the eval timeframe.");
            }
            break;
        case ConditionKind::WHEEL_CONTACTS:
            {
                const uint tempValue = UI::SliderInt(
                    "##wheel_contacts", uint(conditions[conditionInEditor].display), 0, 4);
                conditions[conditionInEditor].display = tempValue;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display;
                UI::TextDimmed(
                    "The car MUST have at least " +
                    tempValue +
                    " wheels contacting the ground in the eval timeframe.");
            }
            break;
        case ConditionKind::CHECKPOINTS:
            {
                const uint tempValue = UI::InputInt(
                    "##checkpoints", uint(conditions[conditionInEditor].display));
                conditions[conditionInEditor].display = tempValue;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display;
                UI::TextDimmed(
                    "The car MUST have collected exactly " +
                    tempValue +
                    " checkpoints in the eval timeframe.");
            }
            break;
        case ConditionKind::GEAR:
            {
                const int tempValue = UI::SliderInt(
                    "##gear", int(conditions[conditionInEditor].display), 0, 5);
                conditions[conditionInEditor].display = tempValue;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display;
                UI::TextDimmed(
                    "The car MUST be in exactly gear " +
                    tempValue +
                    " in the eval timeframe.");
            }
            break;
        case ConditionKind::REAR_GEAR:
            {
                const int tempValue = UI::SliderInt(
                    "##rear_gear", int(conditions[conditionInEditor].display), 0, 1);
                conditions[conditionInEditor].display = tempValue;

                conditions[conditionInEditor].value = conditions[conditionInEditor].display;
                UI::TextDimmed(
                    "The car MUST be in exactly rear gear " +
                    tempValue +
                    " in the eval timeframe.");
            }
            break;
        default:
            UI::TextWrapped("Corrupted condition index: " + conditionInEditor);
            break;
        }

        UI::PopID();
    }
}
