namespace smnu::str
{
    /**
    * Minimal implementation of string wrappers.
    */
    mixin class BaseWrapper
    {
        protected string content;

        string opConv() const
        {
            return content; // property
        }
    }

    /**
    * Wraps a string to allow for handles to be passed around.
    */
    shared class Wrapper : BaseWrapper, Stringifiable
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

    /**
    * Like {Wrapper}, but cannot be modified.
    */
    shared class FrozenWrapper : BaseWrapper, Stringifiable
    {
        FrozenWrapper() { }

        FrozenWrapper(const string &in s)
        {
            content = s;
        }

        string Content
        {
            get const { return content; }
        }
    }
}
