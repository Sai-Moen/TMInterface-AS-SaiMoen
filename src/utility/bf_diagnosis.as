// Bruteforce Diagnosis

const string ID = "bf_diagnosis";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Diagnose Bruteforce.";
    info.Version = "v2.1.0a";
    return info;
}

void Main()
{
    RegisterCustomCommand("diagnosis", "Diagnose Bruteforce Settings.", OnDiagnosis);
}

typedef int ms;

double conditionSpeed;
ms evalMaxTime;
ms evalMinTime;
bool inputsFillSteer;
ms inputsMaxTime;
ms inputsMinTime;
bool keepAllCps;
int maxSteerDiff;
ms maxTimeDiff;
double modifyCount;
ms overrideStopTime;
bool playSound;
string resultFilename;
string target;
int targetCp;
string targetPoint;
int targetTrigger;
double weight;

void SetBfVars()
{
    conditionSpeed   = GetBfDouble("condition_speed");
    evalMaxTime      = GetBfMs("eval_max_time");
    evalMinTime      = GetBfMs("eval_min_time");
    inputsFillSteer  = GetBfBool("inputs_fill_steer");
    inputsMaxTime    = GetBfMs("inputs_max_time");
    inputsMinTime    = GetBfMs("inputs_min_time");
    keepAllCps       = GetBfBool("keep_all_cps");
    maxSteerDiff     = GetBfInt("max_steer_diff");
    maxTimeDiff      = GetBfMs("max_time_diff");
    modifyCount      = GetBfDouble("modify_count");
    overrideStopTime = GetBfMs("override_stop_time");
    playSound        = GetBfBool("play_sound");
    resultFilename   = GetBfString("result_filename");
    target           = GetBfString("target");
    targetCp         = GetBfInt("target_cp");
    targetPoint      = GetBfString("target_point");
    targetTrigger    = GetBfInt("target_trigger");
    weight           = GetBfDouble("weight");
}

bool GetBfBool(const string &in s)     { return GetVariableBool("bf_" + s); }
int GetBfInt(const string &in s)       { return int(GetBfDouble(s)); }
ms GetBfMs(const string &in s)         { return ms(GetBfDouble(s)); }
double GetBfDouble(const string &in s) { return GetVariableDouble("bf_" + s); }
string GetBfString(const string &in s) { return GetVariableString("bf_" + s); }

void OnDiagnosis(int, int, const string &in, const array<string> &in args)
{
    SetBfVars();
    LogBfVars();

    if (!args.IsEmpty())
    {
        ms duration = Time::Parse(args[0]);
        if (duration != -1) DiagnoseDuration(duration);
    }
    
    DiagnoseBehavior();
    DiagnoseOptimization();
    DiagnoseInputModification();
}

void LogBfVars()
{
    log("Bruteforce Vars:");
    log("Condition Speed         = " + conditionSpeed);
    log("Evaluation Maximum Time = " + evalMaxTime);
    log("Evaluation Minimum Time = " + evalMinTime);
    log("Inputs Fill Steer       = " + inputsFillSteer);
    log("Inputs Maximum Time     = " + inputsMaxTime);
    log("Input Minimum Time      = " + inputsMinTime);
    log("Keep All Checkpoints    = " + keepAllCps);
    log("Max Steer Difference    = " + maxSteerDiff);
    log("Max Time Difference     = " + maxTimeDiff);
    log("Modify Count            = " + modifyCount);
    log("Override Stop Time      = " + overrideStopTime);
    log("Play Sound              = " + playSound);
    log("Result Filename         = " + resultFilename);
    log("Target                  = " + target);
    log("Target Checkpoint       = " + targetCp);
    log("Target Point            = " + targetPoint);
    log("Target Trigger          = " + targetTrigger);
    log("Weight                  = " + weight);
    log();
}

void DiagnosisFooter(const bool noProblems)
{
    if (noProblems)
        log("No problems found :-)", Severity::Success);
    log();
}

void DiagnoseDuration(const ms duration)
{
    log("Diagnosing Replay Duration...");
    bool noProblems = true;

    const string replayDuration = "Replay Duration (" + duration + ")";

    if (inputsMinTime >= duration)
    {
        noProblems = false;

        const string var = "Inputs Min Time (" + inputsMinTime + ")";
        log(var + " should be less than the " + replayDuration + " !", Severity::Error);
    }

    if (inputsMaxTime >= duration)
    {
        noProblems = false;

        const string var = "Inputs Max Time (" + inputsMaxTime + ")";
        log(var + " should be less than the " + replayDuration + " !", Severity::Error);
    }

    DiagnosisFooter(noProblems);
}

// Behavior
void DiagnoseBehavior()
{
    log("Diagnosing Behavior...");
    bool noProblems = true;

    const string defaultResultFilename = "result.txt";
    if (resultFilename != defaultResultFilename)
    {
        noProblems = false;

        const string var = "Result Filename (" + resultFilename + ")";
        const string def = "default (" + defaultResultFilename + ")";
        log(var + " is not the " + def + " .", Severity::Warning);
    }

    DiagnosisFooter(noProblems);
}

// Optimization
void DiagnoseOptimization()
{
    log("Diagnosing Optimization...");
    bool noProblems = true;

    if      (target == "finish")     DiagnoseFinish(noProblems);
    else if (target == "checkpoint") DiagnoseCheckpoint(noProblems);
    else if (target == "trigger")    DiagnoseTrigger(noProblems);
    else if (target == "point")      DiagnosePoint(noProblems);
    else                             DiagnoseOther(noProblems);

    DiagnosisFooter(noProblems);
}

void DiagnoseFinish(bool& noProblems)
{
    log("Target is Precise Finish Time.");

    DiagnoseCustomStopTime(noProblems);
}

void DiagnoseCheckpoint(bool& noProblems)
{
    log("Target is Checkpoint Time.");
    log("Target Checkpoint = " + targetCp);

    DiagnoseCustomStopTime(noProblems);
    DiagnoseConditionSpeed(noProblems);
}

void DiagnoseTrigger(bool& noProblems)
{
    log("Target is Trigger.");

    const auto trigger = GetTrigger(targetTrigger);
    if (trigger)
    {
        log("Trigger = " + TriggerToString(trigger));
        log("Weight  = " + weight + "%");
    }
    else
    {
        noProblems = false;

        log("No (valid) trigger selected!", Severity::Error);
    }

    DiagnoseCustomStopTime(noProblems);
    DiagnoseConditionSpeed(noProblems);
}

void DiagnosePoint(bool& noProblems)
{
    log("Target is Single Point.");
    log("Weight = " + weight + "%");

    if (weight != 100)
    {
        const vec3 point = Text::ParseVec3(targetPoint);
        if (point.LengthSquared() == 0)
        {
            noProblems = false;

            const string varPoint = "Target Point (" + targetPoint + ")";
            log(varPoint + " is zeroed, but the weight is not fully set to speed.", Severity::Warning);
        }
        else
        {
            log("Target Point = " + targetPoint);
        }
    }

    if (inputsMinTime == evalMinTime)
    {
        noProblems = false;

        const string varInputs = "Inputs Min Time (" + inputsMinTime + ")";
        const string varEval = "Eval Min Time (" + evalMinTime + ")";
        EvalIsNotInputTimeRant(varInputs, varEval);
    }
    else
    {
        log("Eval Min Time = " + evalMinTime);
    }

    if (inputsMaxTime == evalMaxTime)
    {
        noProblems = false;

        const string varInputs = "Inputs Max Time (" + inputsMaxTime + ")";
        const string varEval = "Eval Max Time (" + evalMaxTime + ")";
        EvalIsNotInputTimeRant(varInputs, varEval);
    }
    else
    {
        log("Eval Max Time = " + evalMaxTime);
    }

    DiagnoseConditionSpeed(noProblems);
}

void DiagnoseOther(bool& noProblems)
{
    log("Target is " + target);

    DiagnoseConditionSpeed(noProblems);
}

void DiagnoseCustomStopTime(bool& noProblems)
{
    if (overrideStopTime == 0) return;

    const string varStop = "Custom Stop Time (" + overrideStopTime + ")";

    if (overrideStopTime < inputsMinTime)
    {
        noProblems = false;

        const string varMin = "Inputs Min Time (" + inputsMinTime + ")";
        log(varStop + " cannot be less than " + varMin + " !", Severity::Error);
    }

    if (overrideStopTime < inputsMaxTime)
    {
        noProblems = false;

        const string varMax = "Inputs Max Time (" + inputsMaxTime + ")";
        log(varStop + " is less than " + varMax + " .", Severity::Warning);
    }
}

void DiagnoseConditionSpeed(bool& noProblems)
{
    if (conditionSpeed == 0) return;

    noProblems = false;

    const string varSpeed = "Condition Speed (" + conditionSpeed + ")";
    log(varSpeed + " is set.", Severity::Warning);
}

void EvalIsNotInputTimeRant(const string &in varInputs, const string &in varEval)
{
    log(varInputs + " and " + varEval + " do not mean the same thing.", Severity::Warning);
    log("Set the evaluation timeframe to around when you expect to reach the point.", Severity::Warning);
}

// Input Modification
void DiagnoseInputModification()
{
    log("Diagnosing Input Modification...");
    bool noProblems = true;

    string varMin = "Inputs Min Time (" + inputsMinTime + ")";
    string varMax = "Inputs Max Time (" + inputsMaxTime + ")";

    if (inputsMinTime > inputsMaxTime)
    {
        noProblems = false;

        log(varMin + " cannot be greater than " + varMax + " !", Severity::Error);
    }

    if (inputsMinTime != 0 && inputsMinTime == inputsMaxTime)
    {
        noProblems = false;

        log(varMin + " is equal to " + varMax + " .", Severity::Warning);
    }

    DiagnosisFooter(noProblems);
}

// utils

void log() { log(""); }

string TriggerToString(const Trigger3D trigger)
{
    const vec3 pos = trigger.Position;
    const vec3 size = trigger.Size;
    return
        ScalarsToString(pos.x, size.x) + " " +
        ScalarsToString(pos.y, size.y) + " " +
        ScalarsToString(pos.z, size.z);
}

string ScalarsToString(const float scalarPos, const float scalarSize)
{
    return scalarPos + "-" + (scalarPos + scalarSize);
}
