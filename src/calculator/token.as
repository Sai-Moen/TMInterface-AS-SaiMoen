namespace Token
{


enum Type
{
    NONE,

    NUMBER,
    OPERATOR, FUNCTION, SEP,
    OPEN, CLOSE,
}

const string SEP = ",";

const string OPEN  = "(";
const string CLOSE = ")";

class Token
{
    Type type;
    number value;

    Token() {}

    Token(Type t, number v = 0)
    {
        type = t;
        value = v;
    }
}


} // namespace Token
