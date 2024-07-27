// Speed Ladder; gradually increases eval timeframe during Speed Bruteforce

const string ID = "speed_ladder";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Speed Ladder Bruteforce";
    info.Version = "v2.1.0b";
    return info;
}

void Main()
{
    OnRegister();
    RegisterBruteforceEvaluation(ID, "Speed Ladder", OnEvaluate, OnSettings);
}

void OnSimulationBegin(SimulationManager@)
{
    // vars (over here because they are backed by strings and the UI element doesn't return vec3)
    yprMin = NormalizeVec3Angle(GetVec3Var(YPR_MIN));
    yprMax = NormalizeVec3Angle(GetVec3Var(YPR_MAX));

    // bruteforce
    nextStep = limit;
    best = 0;
}

vec3 GetVec3Var(const string &in variableName)
{
    return Text::ParseVec3(GetVariableString(variableName));
}

vec3 NormalizeVec3Angle(vec3 angles)
{
    angles.x %= 360;
    angles.y %= 360;
    angles.z %= 360;
    return angles;
}

const string PREFIX = ID + "_";

const string LIMIT     = PREFIX + "limit";
const string EVAL_FROM = PREFIX + "eval_from";
const string EVAL_TO   = PREFIX + "eval_to";

const string MIN_WHEELS = PREFIX + "min_wheels";
const string YPR_MIN    = PREFIX + "ypr_min";
const string YPR_MAX    = PREFIX + "ypr_max";

typedef int ms;
const ms TICK = 10;

const string DEFAULT_VEC3 = vec3().ToString();

uint limit;
ms evalFrom;
ms evalTo;

uint minWheels;
vec3 yprMin;
vec3 yprMax;

void OnRegister()
{
    RegisterVariable(LIMIT, 5000);
    RegisterVariable(EVAL_FROM, 0);
    RegisterVariable(EVAL_TO, 10000);

    RegisterVariable(MIN_WHEELS, 0);
    RegisterVariable(YPR_MIN, DEFAULT_VEC3);
    RegisterVariable(YPR_MAX, DEFAULT_VEC3);


    limit    = uint(GetVariableDouble(LIMIT));
    evalFrom = ms(GetVariableDouble(EVAL_FROM));
    evalTo   = ms(GetVariableDouble(EVAL_TO));

    minWheels = uint(GetVariableDouble(MIN_WHEELS));
}

void OnSettings()
{
    limit    = UI::InputIntVar("Iteration Limit", LIMIT);
    evalFrom = UI::InputTimeVar("Evaluate From", EVAL_FROM);
    evalTo   = UI::InputTimeVar("Evaluate To", EVAL_TO);

    CapMax(EVAL_TO, evalFrom, evalTo);
    evalTo = ms(GetVariableDouble(EVAL_TO));

    minWheels = UI::InputIntVar("Minimum Wheel Contact", MIN_WHEELS);
    UI::DragFloat3Var("Minimum Yaw/Pitch/Roll", YPR_MIN);
    UI::DragFloat3Var("Maximum Yaw/Pitch/Roll", YPR_MAX);
}

void CapMax(const string &in variableName, const ms tfrom, const ms tto)
{
    SetVariable(variableName, Math::Max(tfrom, tto));
}

uint nextStep;

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
{
    BFEvaluationResponse response;

    const uint iterations = info.Iterations;
    if (iterations >= nextStep)
    {
        nextStep = iterations + limit;

        const ms offset = bestTime - evalFrom;
        evalFrom += offset;
        evalTo += offset;

        print("Set eval timeframe to " + evalFrom + "-" + evalTo + ", next step at " + nextStep + " iterations");
    }

    switch (info.Phase)
    {
    case BFPhase::Initial:
        response.Decision = OnInitial(simManager, iterations);
        break;
    case BFPhase::Search:
        response.Decision = OnSearch(simManager);
        break;
    }

    return response;
}

double current;
double best;

ms bestTime;

BFEvaluationDecision OnInitial(SimulationManager@ simManager, uint iterations)
{
    BFEvaluationDecision decision = BFEvaluationDecision::DoNothing;

    const ms time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        best = current;
        bestTime = time;
    }
    else if (IsAfterEvalTime(time))
    {
        print("Best is " + PreciseFormat(best) + " @" + bestTime + "ms w/ " + iterations + " iterations");

        decision = IsSpeedCap(best) ? BFEvaluationDecision::Stop : BFEvaluationDecision::Accept;
    }

    return decision;
}

BFEvaluationDecision OnSearch(SimulationManager@ simManager)
{
    BFEvaluationDecision decision = BFEvaluationDecision::DoNothing;

    const ms time = simManager.RaceTime;
    if (IsEvalTime(time) && IsBetter(simManager))
    {
        decision = BFEvaluationDecision::Accept;
    }
    else if (IsAfterEvalTime(time))
    {
        decision = BFEvaluationDecision::Reject;
    }

    return decision;
}

bool IsBetter(SimulationManager@ simManager)
{
    const auto@ const wheels = simManager.Wheels;

    uint numWheels = 0;
    for (uint i = 0; i < 4; i++)
    {
        numWheels += wheels[i].RTState.HasGroundContact ? 1 : 0;
    }

    if (numWheels < minWheels)
        return false;

    const auto@ const dyna = simManager.Dyna.RefStateCurrent;

    float yaw, pitch, roll;
    dyna.Location.Rotation.GetYawPitchRoll(yaw, pitch, roll);

    if (RejectThisAngle(yprMin.x, yaw, yprMax.x)) return false;
    if (RejectThisAngle(yprMin.y, pitch, yprMax.y)) return false;
    if (RejectThisAngle(yprMin.z, roll, yprMax.z)) return false;

    current = dyna.LinearSpeed.Length() * 3.6;
    return current > best;
}

bool RejectThisAngle(const float minAngle, float angle, const float maxAngle)
{
    if (minAngle == maxAngle)
        return false;

    angle = Math::ToDeg(angle);
    return AngleDiff(angle, minAngle) < 0 || AngleDiff(angle, maxAngle) > 0;
}

float AngleDiff(const float value, const float target)
{
    return (value - target + 540) % 360 - 180;
}

bool IsEvalTime(const ms time)
{
    return time >= evalFrom && time <= evalTo;
}

bool IsAfterEvalTime(const ms time)
{
    return time == evalTo + TICK;
}

string PreciseFormat(const double value)
{
    return Text::FormatFloat(value, "", 0, 6);
}

// need to simulate the floating point error in the game
const float speedCap = 1000.0f / 3.6f * 3.6f;

bool IsSpeedCap(const float value)
{
    return value >= speedCap;
}
