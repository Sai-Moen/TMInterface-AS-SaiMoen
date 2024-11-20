namespace utils
{


void DrawGame(const bool draw)
{
    SetVariable("draw_game", draw);
}

void ExecuteCommands(const bool execute)
{
    SetVariable("execute_commands", execute);
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
