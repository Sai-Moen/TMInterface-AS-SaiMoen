namespace smnu
{
    // Throws an exception and prints the given message
    // It is recommended to catch the exception somewhere
    // param exception: error message to log
    shared void Throw(const string &in exception)
    {
        const uint len = exception.Length;
        if (len > 0)
        {
            log(exception, Severity::Error);
        }
        const uint throw = len / (len ^ len); // fancy
    }
}
