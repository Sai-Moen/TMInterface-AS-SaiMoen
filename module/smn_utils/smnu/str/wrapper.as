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
    shared class Wrapper : BaseWrapper, HandleStr
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
    shared class FrozenWrapper : BaseWrapper, HandleStr
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
