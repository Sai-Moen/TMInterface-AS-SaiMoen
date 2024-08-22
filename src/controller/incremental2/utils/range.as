namespace utils
{


abstract class Range
{
    Range() {}

    Range(const int start, const int stop, const int step)
    {
        this.start = start;
        this.stop = stop;
        this.step = step;
    }

    protected int start;
    protected int stop;
    protected int step;

    bool Done { get const { return true; } }

    int Iter()
    {
        if (Done) return 0;

        const int temp = start;
        start += step;
        return ClampSteer(temp);
    }
}

class RangeIncl : Range
{
    RangeIncl() { super(); }

    RangeIncl(const int start, const int stop, const int step)
    {
        super(start, stop, step);
    }

    bool Done { get const override { return start > stop || step == 0; } }
}

class RangeExcl : Range
{
    RangeExcl() { super(); }

    RangeExcl(const int start, const int stop, const int step)
    {
        super(start, stop, step);
    }

    bool Done { get const override { return start >= stop || step == 0; } }
}


} // namespace utils
