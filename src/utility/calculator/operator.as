namespace Operator
{


enum Type
{
    NONE,

    ADD, SUB,
    MUL, DIV, MOD,
    EXP,
}

const string ADD = "+";
const string SUB = "-";

const string MUL = "*";
const string DIV = "/";
const string MOD = "%";

const string EXP = "^";

dictionary operators =
{
    {ADD, Type::ADD},
    {SUB, Type::SUB},
    
    {MUL, Type::MUL},
    {DIV, Type::DIV},
    {MOD, Type::MOD},
    
    {EXP, Type::EXP}
};

Type Lookup(const string &in op)
{
    uint type;
    if (operators.Get(op, type))
    {
        return Type(type);
    }
    return Type::NONE;
}

bool PrecedenceCmp(const Token::Token token1, const Token::Token token2)
{
    Type type1 = Type(token1.value);
    Type type2 = Type(token2.value);

    int prec1 = Precedence(type1);
    int prec2 = Precedence(type2);

    return prec1 < prec2 || (prec1 == prec2 && LeftAssociative(type1));
}

int Precedence(const Type type)
{
    switch (type)
    {
    case Type::ADD:
    case Type::SUB:
        return 0;
    case Type::MUL:
    case Type::DIV:
    case Type::MOD:
        return 1;
    case Type::EXP:
        return 2;
    }
    return -1;
}

bool LeftAssociative(const Type type)
{
    return type != Type::EXP;
}

Token::Token RunOperator(const Type type, const number left, const number right)
{
    auto token = Token::Token(Token::Type::NUMBER);
    switch (type)
    {
    case Type::ADD:
        token.value = left + right;
        break;
    case Type::SUB:
        token.value = left - right;
        break;
    case Type::MUL:
        token.value = left * right;
        break;
    case Type::DIV:
        token.value = left / right;
        break;
    case Type::MOD:
        token.value = left % right;
        break;
    case Type::EXP:
        token.value = Math::Pow(left, right);
        break;
    }
    return token;
}


} // namespace Operator
