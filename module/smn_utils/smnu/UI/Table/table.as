// https://github.com/ocornut/imgui/blob/master/imgui_tables.cpp

// Before:
/// BeginTable: Begins the table.
/// TableSetupColumn: Gives the column a name (optional), repeated calling advances the column.
/// TableSetupScrollFreeze: Sets up a certain rectangle within the table to be pinned to the screen.

// During:
/// TableHeadersRow / TableHeader
/// TableNextRow
/// TableSetColumnIndex / TableNextColumn

// After:
/// EndTable

namespace smnu::UI::Table
{
}
