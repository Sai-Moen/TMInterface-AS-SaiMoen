// Entry Bruteforce script

namespace Entry
{
    const string ID = ::PrefixVar("entry");
    const string TITLE = "SD Entry Helper";

    const string PrefixVar(const string &in var)
    {
        return ::PrefixVar("entry_" + var);
    }

    const string EVAL_FROM = PrefixVar("eval_from");
    const string EVAL_TO = PrefixVar("eval_to");

    ms evalFrom;
    ms evalTo;

    typedef float score;
    score best;
    array<score> scores;

    void OnRegister()
    {
        RegisterVariable(EVAL_FROM, 0);
        RegisterVariable(EVAL_TO, 10000);

        evalFrom = ms(GetVariableDouble(EVAL_FROM));
        evalTo   = ms(GetVariableDouble(EVAL_TO));

        Resize();

        RegisterBruteforceEvaluation(ID, TITLE, OnEvaluate, OnSettings);
    }

    void OnSettings()
    {
        evalFrom = UI::InputTimeVar("Evaluate from", EVAL_FROM);
        evalTo = UI::InputTimeVar("Evaluate to", EVAL_TO);

        CapMax(EVAL_TO, evalFrom, evalTo);
        evalTo = ms(GetVariableDouble(EVAL_TO));

        Resize();
    }

    void Resize()
    {
        const uint size = GetTickDiff(evalFrom, evalTo) + 1; // Inclusive range so add 1
        if (size > 0xffff)
        {
            log("Large size detected, not resizing!", Severity::Warning);
            return;
        }

        scores.Resize(size);
    }

    BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo &in info)
    {
        BFEvaluationResponse@ const response = BFEvaluationResponse();

        const ms raceTime = simManager.RaceTime;
        if (IsEvalTime(raceTime))
        {
            const uint index = GetTickDiff(evalFrom, raceTime);
            scores[index] = GetScore(simManager);
        }
        else if (IsPastEvalTime(raceTime))
        {
            switch (info.Phase)
            {
            case BFPhase::Initial:
                if (IsAfterEvalTime(raceTime))
                {
                    best = GetAverageScore(scores);
                    print("Best at " + info.Iterations + " = " + best);
                }
                break;
            case BFPhase::Search:
                if (best < GetAverageScore(scores))
                {
                    response.Decision = BFEvaluationDecision::Accept;
                }
                else
                {
                    response.Decision = BFEvaluationDecision::Reject;
                }
                break;
            }
        }

        return response;
    }

    score GetScore(SimulationManager@ simManager)
    {
        return simManager.SceneVehicleCar.TotalCentralForceAdded.z;
    }

    score GetAverageScore(const array<score> &in scores)
    {
        score best = 0;

        const uint len = scores.Length;
        for (uint i = 0; i < len; i++)
        {
            best += scores[i];
        }

        return best / len;
    }

    bool IsEvalTime(const ms raceTime)
    {
        return raceTime >= evalFrom && raceTime <= evalTo;
    }

    bool IsPastEvalTime(const ms raceTime)
    {
        return raceTime > evalTo;
    }

    bool IsAfterEvalTime(const ms raceTime)
    {
        return raceTime == evalTo + TICK;
    }
}
