namespace smnu::str
{
    /**
    * String Builder.
    */
    shared class StringBuilder : Stringifiable
    {
        StringBuilder(const string &in s)
        {
            Content = s;
        }

        StringBuilder(const string &in s, const uint space)
        {
            Content = s;
            const uint len = s.Length;
            if (space < len) return;

            Content.Resize(space);
        }

        protected uint pointer;
        protected string content;

        protected string Content
        {
            get const { return content; }
            set
            {
                content = value;
                pointer = content.Length;
            }
        }

        void Append(const string &in s)
        {
            Content += s; // use pointer
        }

        void AppendLine(const string &in s)
        {
            Content += s + "\n"; // use pointer
        }

        string opConv() const override
        {
            return Content.Substr(0, pointer);
        }
    }
}
