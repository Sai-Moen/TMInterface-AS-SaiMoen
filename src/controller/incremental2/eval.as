namespace Eval
{


// modes
uint modeIndex;
array<string> modeNames;
array<IncMode@> modes;

bool supportsSaveStates;
bool supportsUnlockedTimerange;

funcdef void OnEvent();
OnEvent@ modeRenderSettings;

funcdef void OnSim(SimulationManager@);
OnSim@ modeOnBegin;
OnSim@ modeOnStep;
OnSim@ modeOnEnd;

void Finish(SimulationManager@ simManager)
{
    handledCancel = true;
    onStep = OnStepState::None;
    simManager.ForceFinish();
}

// timestamps
ms tInit;  // the timestamp required to ensure that we can run an entire timerange
ms tState; // the timestamp that the trailing state is saved on
ms tInput; // the timestamp currently being evaluated
ms tLimit; // the timestamp that triggers the end of the simulation when the input time exceeds it

SimulationState@ initState;
SimulationState@ trailingState;

void Bump()
{
    tState += TICK;
    tInput += TICK;
}

bool IsBeforeInitTime(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (time == tInit)
        @initState = simManager.SaveState();
    return time < tInit;
}

bool IsBeforeInputTime(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (time == tState)
        @trailingState = simManager.SaveState();
    return time <= tState;
}

// results


} // namespace Eval
