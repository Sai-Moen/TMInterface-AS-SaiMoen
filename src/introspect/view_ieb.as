// Input Event Buffer view.

void ViewIEB()
{
    const auto@ const ieb = GetSimulationManager().InputEvents;
    if (ieb is null)
    {
        UI::Text("IEB is null");
        return;
    }

    const uint len = ieb.Length;
    UI::Text("IEB Length: " + len);
    UI::Separator();
	if (!VarGetBool(VAR_RAW_IEB))
	{
	    UI::TextWrapped(ieb.ToCommandsText());
	    return;
	}

    if (UI::BeginTable("IEB", 3))
    {
        UI::TableSetupColumn("Time");
        UI::TableSetupColumn("EventIndex");
        UI::TableSetupColumn("Value");

        UI::TableHeadersRow();

        array<int> analogIds;
        if (!VarGetBool(VAR_ORIGINAL_ANALOG))
        {
            const auto eventIndices = ieb.EventIndices;
            analogIds = { eventIndices.SteerId, eventIndices.GasId };
        }

        uint begin, step;
        if (VarGetBool(VAR_REVERSE_RAW_IEB))
        {
            begin = len - 1;
            step = uint(-1);
        }
        else
        {
            begin = 0;
            step = 1;
        }

        for (uint i = begin; i < len; i += step)
        {
            const TM::InputEvent inputEvent = ieb[i];
            UI::TableNextColumn();
            UI::Text("" + inputEvent.Time);

            TM::InputEventValue inputEventValue = inputEvent.Value;
            const int8 eventIndex = inputEventValue.EventIndex;
            UI::TableNextColumn();
            UI::Text("" + eventIndex);

            int value = -inputEventValue.Analog;
            if (analogIds.Find(eventIndex) != -1)
                value = -value;
            UI::TableNextColumn();
            UI::Text("" + value);
        }

        UI::EndTable();
    }
}
