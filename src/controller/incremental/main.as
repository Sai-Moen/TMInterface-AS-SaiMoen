const string ID = "incremental";
const string TITLE = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v2.1.1d";
    return info;
}

bool IsOtherController()
{
    return ID != GetVariableString("controller");
}

void Main()
{
    OnRegister();

    @cancel = OnUserCancelledEmpty;
    @step = OnSimStepEmpty;
    @cpCountChanged = OnCpCountChangedEmpty;
    @end = OnSimEndEmpty;

    RegisterValidationHandler(ID, TITLE, OnSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
        return;

    simManager.RemoveStateValidation();

    const uint duration = simManager.EventsDuration;
    if (Settings::timeTo == 0)
        Eval::Time::max = duration;
    else
        Eval::Time::max = Settings::timeTo;

    auto@ const buffer = simManager.InputEvents;
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Left);
    BufferRemoveAll(buffer, Settings::timeFrom, duration, InputType::Right);

    @cancel = OnUserCancelledMain;
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
    @cpCountChanged = OnCpCountChangedMain;
    @end = OnSimEndMain;
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
    if (userCancelled)
        cancel(simManager);
    else
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

void Finish(SimulationManager@ simManager)
{
    auto@ const buffer = simManager.InputEvents;
    const auto@ const indices = buffer.Find(-1, InputType::FakeFinish);
    if (indices.Length == 1)
    {
        const uint index = indices[0];
        auto event = buffer[index];
        buffer.RemoveAt(index);
        event.Time = Eval::Time::input + 100000; // 100010 - 10
        buffer.Add(event);

        Eval::EndRangeTime(simManager);
    }
    else
    {
        print("Unexpected amount of FakeFinish inputs...", Severity::Error);
    }
    @cancel = OnUserCancelledEmpty;
    @step = OnSimStepEmpty;
    simManager.ForceFinish();
}


/*
    User Cancel handling.
*/
funcdef void OnUserCancelled(SimulationManager@ simManager);
const OnUserCancelled@ cancel;

void OnUserCancelledEmpty(SimulationManager@) {}

void OnUserCancelledMain(SimulationManager@ simManager)
{
    Finish(simManager);
}


/*
    On Simulation Step callback implementation(s).
*/
funcdef void OnSimStep(SimulationManager@ simManager);
const OnSimStep@ step;
const OnSimStep@ backingStep;

void OnSimStepEmpty(SimulationManager@) {}

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
        return;

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
    On Checkpoint Count Changed callback implementation(s).
*/
funcdef void OnCpCountChanged(SimulationManager@ simManager);
const OnCpCountChanged@ cpCountChanged;

void OnCpCountChangedEmpty(SimulationManager@) {}

void OnCpCountChangedMain(SimulationManager@ simManager)
{
    // if we get called it means we are the controller in simulation
    // simply don't finish here as we are supposed to just keep going until the end time
    simManager.PreventSimulationFinish();
}



/*
    On Simulation End callback implementation(s).
*/
funcdef void OnSimEnd(SimulationManager@ simManager);
const OnSimEnd@ end;

void OnSimEndEmpty(SimulationManager@) {}

void OnSimEndMain(SimulationManager@ simManager)
{
    print("Simulation end", Severity::Success);

    Eval::cmdlist.Content = Range::GetBestInputs();
    const string filename = GetVariableString("bf_result_filename");
    if (Eval::cmdlist.Save(filename))
        print("Inputs saved! Filename: " + filename, Severity::Success);
    else
        print("Inputs not saved! Filename: " + filename, Severity::Error);
    Eval::Reset();
    Range::Reset();

    @cpCountChanged = OnCpCountChangedEmpty;
    @end = OnSimEndEmpty;
}
