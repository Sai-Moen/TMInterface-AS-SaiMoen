// Main Script, Strings everything together

const string ID = "incremental";
const string NAME = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = NAME;
    info.Version = "v2.0.1.0";
    return info;
}

void Main()
{
    OnRegister();
    PointCallbacksToEmpty();

    RegisterValidationHandler(ID, NAME, OnSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
    {
        ModeDispatch(NONE::NAME, modeMap, mode);
        return;
    }

    simManager.RemoveStateValidation();

    auto@ const buffer = simManager.InputEvents;
    Eval::cmdlist.Content += buffer.ToCommandsText() + "\n\n";

    const uint duration = simManager.EventsDuration;
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Left);
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Right);

    if (Settings::evalRange)
    {
        @step = OnSimStepRangePre;

        Eval::Time::pre = Settings::timeFrom - TWO_TICKS;

        Range::OnBegin(buffer);
        Eval::inputsResults.Resize(Range::startingTimes.Length);
        Eval::Time::Input = Range::Pop();
    }
    else
    {
        @step = OnSimStepSingle;

        Eval::inputsResults.Resize(1);
        Eval::Time::Input = Settings::timeFrom;
    }
    @end = OnSimEndMain;
    @finished = OnGameFinishMain;
    @Eval::inputsResult = Eval::inputsResults[0];

    ModeDispatch(modeStr, modeMap, mode);
    print(NAME + " : " + modeStr + "\n");
    mode.OnBegin(simManager);
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

void OnCheckpointCountChanged(SimulationManager@ simManager, int current, int target)
{
    if (current == target) finished(simManager);
}

// -------- Callback Implementations --------

dictionary modeMap;
const Mode@ mode;

void PointCallbacksToEmpty()
{
    @step = function(simManager) {};
    @end  = function(simManager) {};

    @finished = function(simManager) {};
}


/*
    On Simulation Step callback implementation(s).
*/
funcdef void OnSimStep(SimulationManager@ simManager);
const OnSimStep@ step;

void OnSimStepSingle(SimulationManager@ simManager)
{
    if (Eval::Time::LimitExceeded())
    {
        simManager.ForceFinish();
        return;
    }
    else if (Eval::BeforeInput(simManager)) return;

    mode.OnStep(simManager);
}

void OnSimStepRangePre(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (time < Eval::Time::pre) return;

    @Range::startingState = simManager.SaveState();
    @step = OnSimStepRangeMain;
}

void OnSimStepRangeMain(SimulationManager@ simManager)
{
    if (Eval::BeforeInput(simManager)) return;
    else if (Eval::Time::LimitExceeded())
    {
        Range::ApplyStartingEvents(simManager.InputEvents);

        if (Range::startingTimes.IsEmpty())
        {
            Eval::EndRangeTime(simManager);
            simManager.ForceFinish();
            return;
        }

        print("");

        Eval::NextRangeTime(simManager);
        mode.OnBegin(simManager);

        simManager.RewindToState(Range::startingState);
        return;
    }

    mode.OnStep(simManager);
}


/*
    On Simulation End callback implementation(s).
*/
funcdef void OnSimEnd(SimulationManager@ simManager);
const OnSimEnd@ end;

void OnSimEndMain(SimulationManager@ simManager)
{
    print("Simulation end", Severity::Success);

    Eval::cmdlist.Content += Range::GetBestInputs();
    if (Eval::cmdlist.Save(GetVariableString("bf_result_filename")))
    {
        log("Inputs saved!", Severity::Success);
    }
    else
    {
        log("Inputs not saved.", Severity::Error);
    }
    Eval::Reset();
    Range::Reset();
    PointCallbacksToEmpty();
}


/*
    Called when the simulation finishes.
*/
funcdef void OnGameFinish(SimulationManager@ simManager);
const OnGameFinish@ finished;

void OnGameFinishMain(SimulationManager@ simManager)
{
    // if we get called it means we are the controller in simulation
    // simply don't finish here as we are supposed to just keep going until the end time
    simManager.PreventSimulationFinish();
}
