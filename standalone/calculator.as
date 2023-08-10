// Shunting yard algorithm ftw

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = "Calculator";
    info.Description = "Can calculate expressions and deal with time";
    info.Version = "v2.0.0.1";
    return info;
}

void Main()
{
    RegisterCustomCommand("calc_expr", "Calculate Expression", OnExpression);
    RegisterCustomCommand("calc_time", "Calculate Time", OnTime);
}

typedef double number;
funcdef number FuncFromText(const string &in text);
const FuncFromText@ FromText;

void OnExpression(
    int fromTime,
    int toTime,
    const string &in commandLine,
    const array<string> &in args)
{
    @FromText = function(text) { return Text::ParseFloat(text); };
    log("expr = " + Text::FormatFloat(Calculate(args)));
}

void OnTime(
    int fromTime,
    int toTime,
    const string &in commandLine,
    const array<string> &in args)
{
    @FromText = function(text) { return number(Time::Parse(text)); };
    log("time = " + Time::FormatPrecise(Calculate(args) / 1000));
}

// Parsing/Calculating

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

        Token(Type _type, number _value = 0)
        {
            type = _type;
            value = _value;
        }
    }
}

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
        int64 type;
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
}

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
        int64 type;
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
}

class Stack
{
    array<Token::Token> stack;

    bool IsEmpty { get { return stack.IsEmpty(); } }

    void Push(const Token::Token token)
    {
        stack.InsertAt(0, token);
    }

    Token::Token Pop()
    {
        const Token::Token token = stack[0];
        stack.RemoveAt(0);
        return token;
    }

    Token::Token Peek()
    {
        if (IsEmpty)
        {
            return Token::Token();
        }
        return stack[0];
    }
}

array<Token::Token> tokens;

number Calculate(const array<string> &in args)
{
    if (args.IsEmpty())
    {
        log("Make sure you are spacing out every element of the expression (commas will work without space)");
        log("Example: 1 + max ( 5, 10 )");
        const array<string> example = {"1", "+", "max", "(", "5,", "10", ")"};
        Tokenize(example);
    }
    else
    {
        Tokenize(args);
    }

    if (Parse())
    {
        return Run();
    }
    return 0;
}

void Tokenize(const array<string> &in args)
{
    tokens.Resize(0);

    for (uint i = 0; i < args.Length; i++)
    {
        const string arg = args[i];

        const array<string>@ const params = arg.Split(Token::SEP);
        for (uint j = 0; j < params.Length; j++)
        {
            const string param = params[j];
            if (param != "")
            {
                FindToken(param);
            }
        }
    }
}

void FindToken(const string &in param)
{
    if (param == Token::OPEN)
    {
        tokens.Add(Token::Token(Token::Type::OPEN));
        return;
    }
    else if (param == Token::CLOSE)
    {
        tokens.Add(Token::Token(Token::Type::CLOSE));
        return;
    }

    const auto op = Operator::Lookup(param);
    if (op != Operator::Type::NONE)
    {
        tokens.Add(Token::Token(Token::Type::OPERATOR, number(op)));
        return;
    }

    const auto fn = Function::Lookup(param);
    if (fn != Function::Type::NONE)
    {
        tokens.Add(Token::Token(Token::Type::FUNCTION, number(fn)));
        return;
    }

    tokens.Add(Token::Token(Token::Type::NUMBER, FromText(param)));
}

array<Token::Token> program;

bool Parse()
{
    program.Resize(0);

    if (tokens.IsEmpty())
    {
        log("No Tokens!", Severity::Error);
        return false;
    }

    Stack opstack;

    for (uint i = 0; i < tokens.Length; i++)
    {
        const Token::Token token = tokens[i];
        switch (token.type)
        {
        case Token::Type::NONE:
            log("Token has no type!", Severity::Error);
            return false;
        case Token::Type::NUMBER:
            program.Add(token);
            break;
        case Token::Type::OPERATOR:
            {
                Token::Token other = opstack.Peek();
                while (Operator::PrecedenceCmp(token, other))
                {
                    program.Add(opstack.Pop());
                    other = opstack.Peek();
                }
            }
        case Token::Type::FUNCTION:
        case Token::Type::OPEN:
            opstack.Push(token);
            break;
        case Token::Type::CLOSE:
            {
                Token::Token maybeOpen = opstack.Peek();
                while (maybeOpen.type != Token::Type::OPEN)
                {
                    if (opstack.IsEmpty)
                    {
                        log("No matching parenthesis!", Severity::Error);
                        return false;
                    }

                    program.Add(opstack.Pop());
                    maybeOpen = opstack.Peek();
                }
            }
            opstack.Pop(); // Discard closing parenthesis

            if (opstack.Peek().type == Token::Type::FUNCTION)
            {
                program.Add(opstack.Pop());
            }
            break;
        }
    }

    while (!opstack.IsEmpty)
    {
        const Token::Token token = opstack.Pop();
        if (token.type == Token::Type::OPEN || token.type == Token::Type::CLOSE)
        {
            log("Mismatched parentheses!", Severity::Error);
            return false;
        }

        program.Add(token);
    }

    return true;
}

number Run()
{
    Stack stack;
    for (uint i = 0; i < program.Length; i++)
    {
        const Token::Token token = program[i];
        switch (token.type)
        {
        case Token::Type::NUMBER:
            stack.Push(token);
            break;
        case Token::Type::OPERATOR:
            {
                Operator::Type type = Operator::Type(token.value);
                stack.Push(RunOperator(type, stack.Pop().value, stack.Pop().value));
            }
            break;
        case Token::Type::FUNCTION:
            {
                Function::Type type = Function::Type(token.value);
                uint amount = Function::ArgumentAmount(type);
                array<number> args(amount);
                for (uint j = 0; j < amount; j++)
                {
                    args[j] = stack.Pop().value;
                }
                stack.Push(RunFunction(type, args));
            }
            break;
        }
    }
    return stack.Pop().value;
}

Token::Token RunOperator(const Operator::Type type, const number left, const number right)
{
    auto token = Token::Token(Token::Type::NUMBER);
    switch (type)
    {
    case Operator::Type::ADD:
        token.value = left + right;
        break;
    case Operator::Type::SUB:
        token.value = left - right;
        break;
    case Operator::Type::MUL:
        token.value = left * right;
        break;
    case Operator::Type::DIV:
        token.value = left / right;
        break;
    case Operator::Type::MOD:
        token.value = left % right;
        break;
    case Operator::Type::EXP:
        token.value = Math::Pow(left, right);
        break;
    }
    return token;
}

Token::Token RunFunction(const Function::Type type, const array<number> &in args)
{
    auto token = Token::Token(Token::Type::NUMBER);
    switch (type)
    {
    case Function::Type::PI:
        token.value = Math::PI;
        break;
    case Function::Type::ABS:
        token.value = Math::Abs(args[0]);
        break;
    case Function::Type::FLOOR:
        token.value = Math::Floor(args[0]);
        break;
    case Function::Type::CEIL:
        token.value = Math::Ceil(args[0]);
        break;
    case Function::Type::ROUND:
        token.value = Math::Round(args[0]);
        break;
    case Function::Type::MIN:
        token.value = Math::Min(args[1], args[0]);
        break;
    case Function::Type::MAX:
        token.value = Math::Max(args[1], args[0]);
        break;
    case Function::Type::CLAMP:
        token.value = Math::Clamp(args[2], args[1], args[0]);
        break;
    case Function::Type::EXP:
        token.value = Math::Exp(args[0]);
        break;
    case Function::Type::SQRT:
        token.value = Math::Sqrt(args[0]);
        break;
    case Function::Type::LOG:
        token.value = Math::Log(args[0]);
        break;
    case Function::Type::LOG2:
        token.value = Math::Log2(args[0]);
        break;
    case Function::Type::LOG10:
        token.value = Math::Log10(args[0]);
        break;
    case Function::Type::DEG:
        token.value = Math::ToDeg(args[0]);
        break;
    case Function::Type::RAD:
        token.value = Math::ToRad(args[0]);
        break;
    case Function::Type::SIN:
        token.value = Math::Sin(args[0]);
        break;
    case Function::Type::COS:
        token.value = Math::Cos(args[0]);
        break;
    case Function::Type::TAN:
        token.value = Math::Tan(args[0]);
        break;
    case Function::Type::ASIN:
        token.value = Math::Asin(args[0]);
        break;
    case Function::Type::ACOS:
        token.value = Math::Acos(args[0]);
        break;
    case Function::Type::ATAN:
        token.value = Math::Atan(args[0]);
        break;
    case Function::Type::ATAN2:
        token.value = Math::Atan2(args[1], args[0]);
        break;
    case Function::Type::RAND:
        token.value = Math::Rand(args[1], args[0]);
        break;
    }
    return token;
}
