namespace SD
{


const string NAME = "SD Railgun";
const string DESCRIPTION = "SpeedDrift scripts.";
const Mode@ const mode = Mode(
    NAME, DESCRIPTION,
    OnRegister, OnSettings,
    OnBegin, OnStep
);

const string PREFIX = ::PREFIX + "sd_";

const string MODE = PREFIX + "mode";

string modeStr;
array<string> modes;

const Mode@ sdMode;
dictionary sdMap;

void OnRegister()
{
    RegisterVariable(MODE, Normal::NAME);

    ModeRegister(sdMap, Normal::mode);
    //ModeRegister(sdMap, Wiggle::mode); // not yet implemented

    modeStr = GetVariableString(MODE);
    ModeDispatch(modeStr, sdMap, sdMode);

    modes = sdMap.GetKeys();
    modes.SortAsc();
}

void OnSettings()
{
    if (ComboHelper("SD Mode", modeStr, modes, ChangeMode))
    {
        DescribeModes("SD Modes:", modes, sdMap);
    }

    sdMode.OnSettings();
}

void ChangeMode(const string &in newMode)
{
    ModeDispatch(newMode, sdMap, sdMode);
    SetVariable(MODE, newMode);
    modeStr = newMode;
}

void OnBegin(SimulationManager@ simManager)
{
    sdMode.OnBegin(simManager);
}

void OnStep(SimulationManager@ simManager)
{
    sdMode.OnStep(simManager);
}

int steer;
RangeIncl range;

array<int> triedSteers;

int bestSteer;
double bestResult;

namespace Normal
{
    const string NAME = "Normal";
    const string DESCRIPTION = "Tries to optimize a given SD automatically.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PREFIX = SD::PREFIX + "normal_";

    const string SEEK = PREFIX + "seek";
    ms seek;

    void OnRegister()
    {
        RegisterVariable(SEEK, 120);
        seek = ms(GetVariableDouble(SEEK));
    }

    void OnSettings()
    {
        seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
    }

    const int RANGE_SIZE = 4;

    const int STEP_DONE = -1;
    const int STEP_LAST_DEVIATION = RANGE_SIZE / 2;

    const OnSim@ onStep;

    void OnBegin(SimulationManager@)
    {
        Reset();
    }

    void OnStep(SimulationManager@ simManager)
    {
        onStep(simManager);
    }

    int step;

    void OnStepPre(SimulationManager@ simManager)
    {
        const float prevTurningRate = Eval::MinState.SceneVehicleCar.TurningRate;
        const float turningRate = simManager.SceneVehicleCar.TurningRate;
        bestSteer = RoundAway(turningRate * STEER::FULL, turningRate - prevTurningRate);

        step = 0x8000 / RANGE_SIZE;
        SetRangeAroundMidpoint(bestSteer);

        @onStep = OnStepMain;
        onStep(simManager);
    }

    void OnStepMain(SimulationManager@ simManager)
    {
        const ms time = simManager.TickTime;
        if (Eval::IsInputTime(time))
        {
            while (!range.Done)
            {
                steer = range.Iter();
                if (triedSteers.Find(steer) == -1)
                {
                    triedSteers.Add(steer);
                    break;
                }
            }
        }
        
        if (Eval::IsEvalTime(time))
        {
            OnEval(simManager);
            Eval::Rewind(simManager);
        }
        else
        {
            Eval::AddInput(simManager, time, InputType::Steer, steer);
        }
    }

    void OnEval(SimulationManager@ simManager)
    {
        const double result = simManager.Dyna.RefStateCurrent.LinearSpeed.Length();
        if (result > bestResult)
        {
            bestResult = result;
            bestSteer = steer;
        }

        if (!range.Done)
            return;

        switch (step)
        {
        case STEP_DONE:
            Eval::Advance(simManager, bestSteer);
            Reset();
            break;
        case 0:
        case 1:
            step = STEP_DONE;
            range = RangeIncl(bestSteer - STEP_LAST_DEVIATION, bestSteer + STEP_LAST_DEVIATION, 1);
            break;
        default:
            step >>= 1;
            SetRangeAroundMidpoint(bestSteer);
            break;
        }
    }

    void Reset()
    {
        triedSteers.Clear();
        bestResult = -1;

        Eval::Time::OffsetEval(seek);
        @onStep = OnStepPre;
    }

    void SetRangeAroundMidpoint(const int midpoint)
    {
        const int offset = step * (RANGE_SIZE - 1) / 2;
        range = RangeIncl(midpoint - offset, midpoint + offset, step);
    }
}

namespace Wiggle
{
    const string NAME = "Wiggle";
    const string DESCRIPTION = "Goes in the direction of the point, switching directions when facing too far away.";
    const Mode@ const mode = Mode(
        NAME, DESCRIPTION,
        OnRegister, OnSettings,
        OnBegin, OnStep
    );

    const string PREFIX = SD::PREFIX + "wiggle_";
    
    const string ANGLE    = PREFIX + "angle";
    const string POSITION = PREFIX + "position";

    const double ANGLE_MIN = 0;
    const double ANGLE_MAX = 45;

    class WiggleContext
    {
        double angle;
        double x;
        double y;
        double z;
    }

    WiggleContext wiggle;

    void OnRegister()
    {
        RegisterVariable(ANGLE, 15);
        RegisterVariable(POSITION, vec3().ToString());

        wiggle.angle = GetVariableDouble(ANGLE);
        const string position = GetVariableString(POSITION);
        vec3 v = Text::ParseVec3(position);
        wiggle.x = v.x;
        wiggle.y = v.y;
        wiggle.z = v.z;
    }

    void OnSettings()
    {
        wiggle.angle = UI::SliderFloatVar("Maximum angle away from point", ANGLE, ANGLE_MIN, ANGLE_MAX);
        wiggle.angle = Math::Clamp(wiggle.angle, ANGLE_MIN, ANGLE_MAX);
        SetVariable(ANGLE, wiggle.angle);

        UI::DragFloat3Var("Point position", POSITION);
        vec3 v = Text::ParseVec3(GetVariableString(POSITION));
        wiggle.x = v.x;
        wiggle.y = v.y;
        wiggle.z = v.z;
    }

    void OnBegin(SimulationManager@ simManager)
    {
    }

    void OnStep(SimulationManager@ simManager)
    {
    }
}


} // namespace SD
