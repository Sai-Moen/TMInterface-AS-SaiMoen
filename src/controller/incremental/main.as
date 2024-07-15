// Main Script, Strings everything together

const string ID = "incremental";
const string NAME = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = NAME;
    info.Version = "v2.1.0a";
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
    print();
    print(NAME + " w/ " + modeStr);
    print();
    mode.OnBegin(simManager);

    if (Settings::useSaveState)
    {
        // cannot load states at this point, temporarily dispatch to special step function
        @backingStep = step;
        @step = OnSimStepState;
    }
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
const OnSimStep@ backingStep;

void OnSimStepState(SimulationManager@ simManager)
{
    const auto@ const start = simManager.SaveState();
    Settings::TryLoadStateFile(simManager);
    if (Eval::OutOfBounds(simManager.RaceTime))
    {
        print("Attempted to load state that occurs too late! Reverting to start...", Severity::Warning);
        simManager.RewindToState(start);
    }

    @step = backingStep;
    @backingStep = null;
}

void OnSimStepSingle(SimulationManager@ simManager)
{
    if (Eval::LimitExceeded())
    {
        Eval::EndRangeTime(simManager);
        simManager.ForceFinish();
        return;
    }
    else if (Eval::BeforeInput(simManager)) return;

    mode.OnStep(simManager);
}

void OnSimStepRangePre(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (Eval::BeforeRange(time)) return;

    @Range::startingState = simManager.SaveState();
    @step = OnSimStepRangeMain;
}

void OnSimStepRangeMain(SimulationManager@ simManager)
{
    if (Eval::BeforeInput(simManager)) return;
    else if (Eval::LimitExceeded())
    {
        print();

        if (Range::startingTimes.IsEmpty())
        {
            Eval::EndRangeTime(simManager);
            simManager.ForceFinish();
            return;
        }

        Range::ApplyStartingEvents(simManager.InputEvents);

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

    Eval::cmdlist.Content = Range::GetBestInputs();
    const string filename = GetVariableString("bf_result_filename");
    if (Eval::cmdlist.Save(filename))
    {
        log("Inputs saved! Filename: " + filename, Severity::Success);
    }
    else
    {
        log("Inputs not saved! Filename: " + filename, Severity::Error);
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
