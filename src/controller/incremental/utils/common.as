namespace utils
{


string PreciseFormat(const double value)
{
    return Text::FormatFloat(value, " ", 0, 6);
}

InputCommand MakeInputCommand(const ms timestamp, const InputType type, const int state)
{
    InputCommand cmd;
    cmd.Timestamp = timestamp;
    cmd.Type = type;
    cmd.State = state;
    return cmd;
}


} // namespace utils
