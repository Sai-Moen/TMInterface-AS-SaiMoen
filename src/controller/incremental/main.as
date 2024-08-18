const string ID = "incremental";
const string TITLE = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v2.1.1c";
    return info;
}

bool IsOtherController()
{
    return ID != GetVariableString("controller");
}

void Main()
{
    OnRegister();
    PointCallbacksToEmpty();

    RegisterValidationHandler(ID, TITLE, OnSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
    {
        ModeDispatch(NONE::NAME, modeMap, mode);
        return;
    }

    simManager.RemoveStateValidation();
    const uint duration = simManager.EventsDuration;
    simManager.SetSimulationTimeLimit(Math::INT_MAX);

    if (Settings::timeTo == 0)
        Eval::Time::max = duration;
    else
        Eval::Time::max = Settings::timeTo;

    auto@ const buffer = simManager.InputEvents;
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Left);
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Right);

    @onCancel = OnUserCancelledMain;
    if (Settings::evalRange)
    {
        @step = OnSimStepRangePre;

        Eval::Time::pre = Settings::timeFrom - TickToMs(2);

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
    @cpCountChanged = OnCpCountChangedMain;
    @Eval::inputsResult = Eval::inputsResults[0];

    if (Eval::Time::min > Eval::Time::max)
    {
        print("Min eval time is greater than Max eval time.", Severity::Error);
        Finish(simManager);
        return;
    }

    if (Settings::useSaveState)
    {
        // cannot load states at this point, temporarily dispatch to special step function
        @backingStep = step;
        @step = OnSimStepState;
    }

    ModeDispatch(modeStr, modeMap, mode);
    print();
    print(TITLE + " w/ " + modeStr);
    print();
    mode.OnBegin(simManager);
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    if (onCancel(simManager, userCancelled))
        return;
    step(simManager);
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult)
{
    end(simManager);
}

void OnCheckpointCountChanged(SimulationManager@ simManager, int, int)
{
    cpCountChanged(simManager);
}

// -------- Callback Implementations --------

dictionary modeMap;
const Mode@ mode;

void PointCallbacksToEmpty()
{
    @onCancel = function(simManager, userCancelled) { return true; };
    @step = function(simManager) {};
    @end = function(simManager) {};
    @cpCountChanged = function(simManager) {};
}

void Finish(SimulationManager@ simManager)
{
    Eval::EndRangeTime(simManager);
    simManager.ForceFinish();
}


/*
    User Cancel handling.
*/
funcdef bool OnUserCancelled(SimulationManager@ simManager, bool userCancelled);
const OnUserCancelled@ onCancel;

bool OnUserCancelledMain(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled)
        Finish(simManager);
    return userCancelled;
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
        Finish(simManager);
        return;
    }
    else if (Eval::BeforeInput(simManager))
    {
        return;
    }

    mode.OnStep(simManager);
}

void OnSimStepRangePre(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (Eval::BeforeRange(time))
    {
        return;
    }

    @Range::startingState = simManager.SaveState();
    @step = OnSimStepRangeMain;
}

void OnSimStepRangeMain(SimulationManager@ simManager)
{
    if (Eval::LimitExceeded())
    {
        print();

        if (Range::startingTimes.IsEmpty())
        {
            Finish(simManager);
            return;
        }

        Range::ApplyStartingEvents(simManager.InputEvents);

        Eval::NextRangeTime(simManager);
        mode.OnBegin(simManager);

        simManager.RewindToState(Range::startingState);
        return;
    }
    else if (Eval::BeforeInput(simManager))
    {
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
funcdef void OnCpCountChanged(SimulationManager@ simManager);
const OnCpCountChanged@ cpCountChanged;

void OnCpCountChangedMain(SimulationManager@ simManager)
{
    // if we get called it means we are the controller in simulation
    // simply don't finish here as we are supposed to just keep going until the end time
    simManager.PreventSimulationFinish();
}
