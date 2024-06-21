// Smooth inputs

const string ID = "smooth_inputs";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Attempts to generate the least chaotic set of inputs that is identical to the run.";
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    OnRegister();
    RegisterValidationHandler(ID, "Inputs Smoother", OnSettings);
}

const string PREFIX = ID + "_";

const string USE_CUSTOM_FILENAME = PREFIX + "use_custom_filename";
const string FILENAME            = PREFIX + "filename";

void OnRegister()
{
    RegisterVariable(USE_CUSTOM_FILENAME, true);
    RegisterVariable(FILENAME, GetResultFilename());
}

void OnSettings()
{
    const bool useCustomFilename = UI::CheckboxVar("Use Custom Filename?", USE_CUSTOM_FILENAME);
    UI::BeginDisabled(!useCustomFilename);
    UI::InputTextVar("File to save to", FILENAME);
    UI::EndDisabled();
}

TM::InputEventBuffer@ buffer;

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
    {
        @step = function(simManager) {};
        @end = function(simManager) {};
        return;
    }

    simManager.RemoveStateValidation();
    @buffer = simManager.InputEvents;

    @step = OnStep;
    @end = OnEnd;
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled)
    {
        simManager.ForceFinish();
        return;
    }

    step(simManager);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult)
{
    end(simManager);
}

funcdef void SimStep(SimulationManager@);
const SimStep@ step;

void OnStep(SimulationManager@ simManager)
{
    const int time = simManager.RaceTime;
    if (time > duration)
    {
        simManager.ForceFinish();
        return;
    }
    else if (time < 0) return;

    //
}

funcdef void SimEnd(SimulationManager@);
const SimEnd@ end;

void OnEnd(SimulationManager@)
{
    CommandList output;
    output.Content = buffer.ToCommandsText();
    @buffer = null;

    const string filename = GetResultFilename();
    if (output.Save(filename))
    {
        log("Saved to: " + filename, Severity::Success);
    }
    else
    {
        log("Could not save to: " + filename, Severity::Error);
    }
}

string GetResultFilename()
{
    return GetVariableBool(USE_CUSTOM_FILENAME) ? GetVariableString(FILENAME) : GetVariableString("bf_result_filename");
}
