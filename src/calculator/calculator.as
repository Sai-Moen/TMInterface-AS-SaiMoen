// Shunting yard algorithm ftw

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Author = "SaiMoen";
    info.Name = "Calculator";
    info.Description = "Can calculate expressions and deal with time";
    info.Version = "v2.1.0a";
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

void OnExpression(int, int, const string &in, const array<string> &in args)
{
    @FromText = function(text) { return Text::ParseFloat(text); };
    log("expr = " + Calculate(args));
}

void OnTime(int, int, const string &in, const array<string> &in args)
{
    @FromText = function(text) { return number(Time::Parse(text)); };
    log("time = " + Time::FormatPrecise(Calculate(args) / 1000));
}

class Stack
{
    array<Token::Token> stack;

    bool IsEmpty { get { return stack.IsEmpty(); } }
    uint Length { get { return stack.Length; } }

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

array<Token::Token> tokens;

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
            if (!param.IsEmpty())
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
        const auto token = tokens[i];
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
                auto other = opstack.Peek();
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
                auto maybeOpen = opstack.Peek();
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
        const auto token = opstack.Pop();
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
        const auto token = program[i];
        switch (token.type)
        {
        case Token::Type::NUMBER:
            stack.Push(token);
            break;
        case Token::Type::OPERATOR:
            {
                Operator::Type type = Operator::Type(token.value);
                if (stack.Length < 2)
                {
                    const auto temp = stack.Pop();
                    stack.Push(Token::Token(Token::Type::NUMBER));
                    stack.Push(temp);
                }
                stack.Push(Operator::RunOperator(type, stack.Pop().value, stack.Pop().value));
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
                stack.Push(Function::RunFunction(type, args));
            }
            break;
        }
    }
    return stack.Pop().value;
}
