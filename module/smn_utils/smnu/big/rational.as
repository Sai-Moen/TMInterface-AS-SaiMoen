namespace smnu
{
    /**
    * A number that can theoretically occupy infinite memory in order to represent any rational number.
    * Implementation: BigInteger numerator, BigInteger denominator.
    */
    shared class BigRational : Stringifiable
    {
        BigRational() { }

        protected BigInteger@ numerator;
        protected BigInteger@ denominator;

        string opConv() const override
        {
            return string(numerator) + "\n/\n" + string(denominator);
        }
    }
}
