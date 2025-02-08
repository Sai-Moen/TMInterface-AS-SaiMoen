namespace utils
{


string PreciseFormat(const double value)
{
    return Text::FormatFloat(value, " ", 0, 6);
}


} // namespace utils
