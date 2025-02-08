namespace Function
{


enum Type
{
    NONE,

    PI,

    ABS,
    FLOOR, CEIL, ROUND,
    MIN, MAX, CLAMP,

    EXP, SQRT,
    LOG, LOG2, LOG10,
    
    DEG, RAD,
    SIN, COS, TAN,
    ASIN, ACOS, ATAN,
    ATAN2,

    RAND,
}

const string PI = "pi";

const string ABS = "abs";
const string FLOOR = "floor";
const string CEIL = "ceil";
const string ROUND = "round";
const string MIN = "min";
const string MAX = "max";
const string CLAMP = "clamp";

const string EXP = "exp";
const string SQRT = "sqrt";
const string LOG = "log";
const string LOG2 = "log2";
const string LOG10 = "log10";

const string DEG = "deg";
const string RAD = "rad";
const string SIN = "sin";
const string COS = "cos";
const string TAN = "tan";
const string ASIN = "asin";
const string ACOS = "acos";
const string ATAN = "atan";
const string ATAN2 = "atan2";

const string RAND = "rand";

dictionary functions =
{
    {PI,    Type::PI},

    {ABS,   Type::ABS},
    {FLOOR, Type::FLOOR},
    {CEIL,  Type::CEIL},
    {ROUND, Type::ROUND},
    {MIN,   Type::MIN},
    {MAX,   Type::MAX},
    {CLAMP, Type::CLAMP},
    
    {EXP,   Type::EXP},
    {SQRT,  Type::SQRT},
    {LOG,   Type::LOG},
    {LOG2,  Type::LOG2},
    {LOG10, Type::LOG10},
    
    {DEG,   Type::DEG},
    {RAD,   Type::RAD},
    {SIN,   Type::SIN},
    {COS,   Type::COS},
    {TAN,   Type::TAN},
    {ASIN,  Type::ASIN},
    {ACOS,  Type::ACOS},
    {ATAN,  Type::ATAN},
    {ATAN2, Type::ATAN2},
    
    {RAND,  Type::RAND}
};

Type Lookup(const string &in fn)
{
    uint type;
    if (functions.Get(fn, type))
    {
        return Type(type);
    }
    return Type::NONE;
}

uint ArgumentAmount(Type type)
{
    switch (type)
    {
    case Type::PI:
        return 0;
    case Type::ABS:
    case Type::FLOOR:
    case Type::CEIL:
    case Type::ROUND:
    case Type::EXP:
    case Type::SQRT:
    case Type::LOG:
    case Type::LOG2:
    case Type::LOG10:
    case Type::DEG:
    case Type::RAD:
    case Type::SIN:
    case Type::COS:
    case Type::TAN:
    case Type::ASIN:
    case Type::ACOS:
    case Type::ATAN:
        return 1;
    case Type::MIN:
    case Type::MAX:
    case Type::ATAN2:
    case Type::RAND:
        return 2;
    case Type::CLAMP:
        return 3;
    }
    return 0;
}

Token::Token RunFunction(const Type type, const array<number> &in args)
{
    auto token = Token::Token(Token::Type::NUMBER);
    switch (type)
    {
    case Type::PI:
        token.value = Math::PI;
        break;
    case Type::ABS:
        token.value = Math::Abs(args[0]);
        break;
    case Type::FLOOR:
        token.value = Math::Floor(args[0]);
        break;
    case Type::CEIL:
        token.value = Math::Ceil(args[0]);
        break;
    case Type::ROUND:
        token.value = Math::Round(args[0]);
        break;
    case Type::MIN:
        token.value = Math::Min(args[1], args[0]);
        break;
    case Type::MAX:
        token.value = Math::Max(args[1], args[0]);
        break;
    case Type::CLAMP:
        token.value = Math::Clamp(args[2], args[1], args[0]);
        break;
    case Type::EXP:
        token.value = Math::Exp(args[0]);
        break;
    case Type::SQRT:
        token.value = Math::Sqrt(args[0]);
        break;
    case Type::LOG:
        token.value = Math::Log(args[0]);
        break;
    case Type::LOG2:
        token.value = Math::Log2(args[0]);
        break;
    case Type::LOG10:
        token.value = Math::Log10(args[0]);
        break;
    case Type::DEG:
        token.value = Math::ToDeg(args[0]);
        break;
    case Type::RAD:
        token.value = Math::ToRad(args[0]);
        break;
    case Type::SIN:
        token.value = Math::Sin(args[0]);
        break;
    case Type::COS:
        token.value = Math::Cos(args[0]);
        break;
    case Type::TAN:
        token.value = Math::Tan(args[0]);
        break;
    case Type::ASIN:
        token.value = Math::Asin(args[0]);
        break;
    case Type::ACOS:
        token.value = Math::Acos(args[0]);
        break;
    case Type::ATAN:
        token.value = Math::Atan(args[0]);
        break;
    case Type::ATAN2:
        token.value = Math::Atan2(args[1], args[0]);
        break;
    case Type::RAND:
        token.value = Math::Rand(args[1], args[0]);
        break;
    }
    return token;
}


} // namespace Function
