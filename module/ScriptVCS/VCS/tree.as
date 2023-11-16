class Tree
{
    Tree(CommandList@ _script)
    {
        @script = _script;
        branches = array<Branch>();
    }

    CommandList@ script;
    array<Branch> branches;
}
