const string VAR = ID + "_";

const string VAR_EVAL_FROM = VAR + "eval_from";
const string VAR_EVAL_TO   = VAR + "eval_to";

const string VAR_TARGET_GROUPED = VAR + "target_grouped";
const string VAR_TARGET_MODE    = VAR + "target_mode";
const string VAR_TARGET_GROUP   = VAR + "target_group";
const string VAR_TARGET_VALUE   = VAR + "target_value";
const string VAR_TARGET_TOWARDS = VAR + "target_towards";

ms evalFrom;
ms evalTo;

bool isTargetGrouped;
ModeKind targetMode;
GroupKind targetGroup;
int targetTowards;
double targetValue;

void RegisterSettings()
{
    RegisterVariable(VAR_EVAL_FROM, 0);
    RegisterVariable(VAR_EVAL_TO,   0);

    RegisterVariable(VAR_TARGET_GROUPED, true);
    RegisterVariable(VAR_TARGET_MODE,    0);
    RegisterVariable(VAR_TARGET_GROUP,   0);
    RegisterVariable(VAR_TARGET_TOWARDS, 0);
    RegisterVariable(VAR_TARGET_VALUE,   0);

    evalFrom = ms(GetVariableDouble(VAR_EVAL_FROM));
    evalTo   = ms(GetVariableDouble(VAR_EVAL_TO));

    isTargetGrouped = GetVariableBool(VAR_TARGET_GROUPED);
    targetMode      = ModeKind(GetVariableDouble(VAR_TARGET_MODE));
    targetGroup     = GroupKind(GetVariableDouble(VAR_TARGET_GROUP));
    targetTowards   = int(GetVariableDouble(VAR_TARGET_TOWARDS));
    targetValue     = GetVariableDouble(VAR_TARGET_VALUE);
}

const string HIDDEN_EDITOR_LABEL = "<Hide>";

GroupKind groupInEditor = GroupKind::NONE;

void RenderSettings()
{
    evalFrom = UI::InputTimeVar("Evaluate From", VAR_EVAL_FROM);
    evalTo   = UI::InputTimeVar("Evaluate To",   VAR_EVAL_TO);
    if (evalTo < evalFrom)
        SetVariable(VAR_EVAL_TO, evalTo = evalFrom);

    isTargetGrouped = UI::CheckboxVar("Grouped Target?", VAR_TARGET_GROUPED);
    if (isTargetGrouped)
    {
        ComboHelper("Target (Group):", targetGroup, groupNames,
            function(index)
            {
                targetGroup = GroupKind(index);
                SetVariable(VAR_TARGET_GROUP, targetGroup);
            }
        );
    }
    else
    {
        ComboHelper("Target (Mode):", targetMode, modeNames,
            function(index)
            {
                targetMode = ModeKind(index);
                SetVariable(VAR_TARGET_MODE, targetMode);
            }
        );
    }

    targetTowards = UI::SliderIntVar("Target Towards", VAR_TARGET_TOWARDS, -1, 1);
    bool disableTarget;
    string targetTowardsMessage;
    switch (targetTowards)
    {
    case -1:
        disableTarget = true;
        targetTowardsMessage = "Lower value is better";
        break;
    case 1:
        disableTarget = true;
        targetTowardsMessage = "Higher value is better";
        break;
    default:
        disableTarget = false;
        targetTowardsMessage = "Custom";
        break;
    }
    UI::TextDimmed(targetTowardsMessage);

    UI::BeginDisabled(disableTarget);
    targetValue = UI::InputFloatVar("Target Value", VAR_TARGET_VALUE);
    UI::EndDisabled();

    const bool isGroupInEditorOldHidden = groupInEditor == GroupKind::NONE;
    const string currentGroup = isGroupInEditorOldHidden ? HIDDEN_EDITOR_LABEL : groupNames[groupInEditor];
    if (UI::BeginCombo("Group/Mode Editor", currentGroup))
    {
        UI::PushID("group_editor");

        if (UI::Selectable(HIDDEN_EDITOR_LABEL, isGroupInEditorOldHidden))
            groupInEditor = GroupKind::NONE;

        for (uint i = 0; i < GroupKind::COUNT; i++)
        {
            UI::PushID("" + i);

            groups[i].active = UI::Checkbox("##active", groups[i].active);
            UI::SameLine();
            const GroupKind kind = GroupKind(i);
            if (UI::Selectable(groupNames[i], groupInEditor == kind))
                groupInEditor = kind;

            UI::PopID();
        }

        UI::PopID();
        UI::EndCombo();
    }

    array<ModeKind> modesToRender;
    if (GroupKindToModeKinds(groupInEditor, modesToRender))
    {
        UI::PushID("group_in_editor");

        for (uint i = 0; i < modesToRender.Length; i++)
        {
            UI::Separator();

            UI::PushID("" + i);

            const ModeKind modeKind = modesToRender[i];
            UI::TextWrapped(modeNames[modeKind]);

            modes[modeKind].lower = UI::Checkbox("Lower Bound", modes[modeKind].lower);
            UI::SameLine();
            modes[modeKind].upper = UI::Checkbox("Upper Bound", modes[modeKind].upper);

            UI::PushItemWidth(192);

            UI::BeginDisabled(!modes[modeKind].lower);
            modes[modeKind].lowerValue = UI::InputFloat("##lower", modes[modeKind].lowerValue);
            UI::EndDisabled();
            UI::SameLine();
            UI::BeginDisabled(!modes[modeKind].upper);
            modes[modeKind].upperValue = UI::InputFloat("##upper", modes[modeKind].upperValue);
            UI::EndDisabled();

            UI::PopItemWidth();

            UI::PopID();
        }

        UI::PopID();
    }

    // TODO: Render conditions
}
