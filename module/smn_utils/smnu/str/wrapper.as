namespace smnu::str
{
    // Minimal implementation of string wrappers
    mixin class Base
    {
        protected string content;

        string opConv() const
        {
            return Content; // property
        }
    }

    // Wraps a string to allow for handles to be passed around
    shared class Wrapper : Base, HandleStr
    {
        Wrapper() { }

        Wrapper(const string &in s)
        {
            content = s;
        }

        string Content
        {
            get const { return content; }
            set { content = value; }
        }
    }

    // Like Wrapper, but cannot be modified
    shared class Frozen : Base, HandleStr
    {
        Frozen() { }

        Frozen(const string &in s)
        {
            content = s;
        }

        string Content
        {
            get const { return content; }
        }
    }
}
