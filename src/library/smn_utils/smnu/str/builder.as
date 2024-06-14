namespace smnu::str
{
    /**
    * String Builder.
    */
    shared class StringBuilder : Stringifiable
    {
        private const string NEWLINE { get const { return "\n"; } }

        StringBuilder() { }

        StringBuilder(const string &in s)
        {
            Content = s;
        }

        StringBuilder(const string &in s, const uint space)
        {
            Content = s;
            const uint len = s.Length;
            if (space > len)
            {
                IncreaseSize(space - len);
            }
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

        protected void IncreaseSize(const uint increase)
        {
            Content.Resize(Content.Length + increase);
        }


        void Append()
        {
            Append(" ");
        }

        void Append(const string &in s)
        {
            uint i = 0;
            while (pointer < Content.Length)
            {
                if (i >= s.Length) return;
                Content[pointer++] = s[i++];
            }

            if (i < s.Length)
            {
                Content += s.Substr(i);
            }
        }

        void Append(const bool s)   { Append(ingify(s)); }
        void Append(const uint s)   { Append(ingify(s)); }
        void Append(const uint64 s) { Append(ingify(s)); }
        void Append(const int s)    { Append(ingify(s)); }
        void Append(const int64 s)  { Append(ingify(s)); }
        void Append(const float s)  { Append(ingify(s)); }
        void Append(const double s) { Append(ingify(s)); }

        void Append(const dictionaryValue s)      { Append(ingify(s)); }
        void Append(const Stringifiable@ const s) { Append(ingify(s)); }


        void AppendLine()
        {
            Append(NEWLINE);
        }

        void AppendLine(const string &in s)
        {
            Append(s + NEWLINE);
        }

        void AppendLine(const bool s)   { AppendLine(ingify(s)); }
        void AppendLine(const uint s)   { AppendLine(ingify(s)); }
        void AppendLine(const uint64 s) { AppendLine(ingify(s)); }
        void AppendLine(const int s)    { AppendLine(ingify(s)); }
        void AppendLine(const int64 s)  { AppendLine(ingify(s)); }
        void AppendLine(const float s)  { AppendLine(ingify(s)); }
        void AppendLine(const double s) { AppendLine(ingify(s)); }

        void AppendLine(const dictionaryValue s)      { AppendLine(ingify(s)); }
        void AppendLine(const Stringifiable@ const s) { AppendLine(ingify(s)); }


        void AppendAll(const array<string>@ const all, const string &in sep = "")
        {
            if (all.IsEmpty()) return;

            uint sum = 0;
            for (uint i = 0; i < all.Length; i++)
            {
                sum += all[i].Length + sep.Length;
            }
            IncreaseSize(sum - sep.Length);

            Append(Text::Join(all, sep));
        }

        string opConv() const override
        {
            return Content.Substr(0, pointer);
        }
    }
}
