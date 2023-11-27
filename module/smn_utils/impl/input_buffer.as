namespace smnu::IB
{
    // Makes InputCommand based on the three required parameters
    // param timestamp: time of the input
    // param type: type of the input (see api/global/InputType)
    // param state: state of the input
    // returns: a new InputCommand
    shared InputCommand MakeInputCommand(const ms timestamp, const InputType type, const int state)
    {
        InputCommand cmd;
        cmd.Timestamp = timestamp;
        cmd.Type = type;
        cmd.State = state;
        return cmd;
    }

    // Checks if the previous input differs from the current one
    // param buffer: the InputEventBuffer
    // param time: time to look for
    // param type: type to look for
    // param current: current state of the input, of type T
    // returns: whether the previous input was different from the current one
    //  shared bool DiffPreviousInput(
    //      TM::InputEventBuffer@ const buffer,
    //      const ms time,
    //      const InputType type,
    //      T& current);

    shared bool DiffPreviousInput(
        TM::InputEventBuffer@ const buffer,
        const ms time,
        const InputType type,
        bool& current)
    {
        const bool new = GetLast(buffer, time, type, current);
        const bool old = current;
        current = new;
        return new != old;
    }

    shared bool DiffPreviousInput(
        TM::InputEventBuffer@ const buffer,
        const ms time,
        const InputType type,
        int& current)
    {
        const int new = GetLast(buffer, time, type, current);
        const int old = current;
        current = new;
        return new != old;
    }

    // Gets the state of the last input, or the current one if there is no new input
    // param buffer: the InputEventBuffer
    // param time: time to look for
    // param type: type to look for
    // param current: current state of the input, of type T
    // returns: the state of the most up-to-date input, of type T
    //  shared T GetLast(
    //      TM::InputEventBuffer@ const buffer,
    //      const ms time,
    //      const InputType type,
    //      const T current);

    shared bool GetLast(
        TM::InputEventBuffer@ const buffer,
        const ms time,
        const InputType type,
        const bool current)
    {
        const auto@ const indices = buffer.Find(time, type);
        if (indices.IsEmpty()) return current;

        return buffer[indices[indices.Length - 1]].Value.Binary;
    }

    shared int GetLast(
        TM::InputEventBuffer@ const buffer,
        const ms time,
        const InputType type,
        const int current)
    {
        const auto@ const indices = buffer.Find(time, type);
        if (indices.IsEmpty()) return current;

        return buffer[indices[indices.Length - 1]].Value.Analog;
    }

    // Removes all inputs of a certain type in the range [start, end]
    // param buffer: the InputEventBuffer
    // param start: the starting time
    // param end: the stopping time
    // param type: the type of input to remove
    shared void RemoveAll(
        TM::InputEventBuffer@ const buffer,
        const ms start,
        const ms end,
        const InputType type)
    {
        for (ms i = start; i <= end; i += TICK())
        {
            RemoveIndices(buffer, buffer.Find(i, type));
        }
    }

    // Removes the given indices from the buffer
    // param buffer: the InputEventBuffer
    // param indices: the indices to remove from buffer
    shared void RemoveIndices(TM::InputEventBuffer@ const buffer, const array<uint>@ const indices)
    {
        if (indices.IsEmpty()) return;

        uint contiguous = 1;
        uint old = indices[indices.Length - 1];
        for (int i = indices.Length - 2; i >= 0; i--)
        {
            const uint new = indices[i];
            if (new == old - 1)
            {
                contiguous++;
            }
            else
            {
                buffer.RemoveAt(old, contiguous);
                contiguous = 1;
            }
            old = new;
        }
        buffer.RemoveAt(old, contiguous);
    }
}
