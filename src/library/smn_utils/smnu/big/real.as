namespace smnu
{
    /**
    * A number that can theoretically occupy infinite memory in order to represent any real number.
    * Implementation: bool sign, BigInteger exponent, BigInteger significand/mantissa.
    */
    shared class BigReal : Stringifiable
    {
        BigReal() { }

        protected bool negative;
        protected BigInteger@ exponent;
        protected BigInteger@ significand;

        string opConv() const override
        {
            string builder;
            builder += negative ? "1" : "0";
            builder += " ";
            builder += exponent.Binary();
            builder += " ";
            builder += significand.Binary();
            return builder + "\n";
        }
    }
}
