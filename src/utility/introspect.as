// SaveState introspection

const string ID = "introspect";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = "Save State Introspection";
    info.Version = "v2.1.1a";
    return info;
}

void Main()
{
    OnRegister();
    RegisterCustomCommand(ID, "Toggle Introspection Window", OnIntrospect);
}

const string PREFIX = ID + "_";

const string ENABLED = PREFIX + "enabled";
bool enabled;

const string SPAM = PREFIX + "spam";
bool spam;

void OnRegister()
{
    RegisterVariable(ENABLED, false);
    RegisterVariable(SPAM, false);

    enabled = GetVariableBool(ENABLED);
    spam = GetVariableBool(SPAM);
}

void OnIntrospect(int, int, const string &in, const array<string> &in)
{
    SetVariable(ENABLED, enabled = !enabled);
}

void Render()
{
    if (!enabled)
        return;

    if (UI::Begin("Introspect"))
        Window();
    UI::End();
}

bool floatView;

array<uint> offsetStack = { 0 };
array<Struct@> structStack = { SimStateData() };

const array<uint8>@ state;

void Window()
{
    spam = UI::CheckboxVar("Spam Console", SPAM);

    UI::BeginDisabled(!spam);
    floatView = UI::Checkbox("Float View", floatView);
    UI::EndDisabled();

    const uint lastIndex = offsetStack.Length - 1;
    for (uint i = 0; i <= lastIndex; i++)
    {
        UI::PushID("offset" + i);

        UI::BeginDisabled(i != lastIndex);
        offsetStack[i] = UI::InputInt("Offset", offsetStack[i], 4);
        UI::EndDisabled();

        UI::PopID();
    }

    if (UI::Button("Up one level") && lastIndex > 0)
    {
        offsetStack.RemoveAt(lastIndex);
        structStack.RemoveAt(lastIndex);
        return;
    }

    UI::Separator();

    Struct@ const struct = structStack[lastIndex];
    UI::TextWrapped(struct.Name());

    const StructType type = struct.Type();
    switch (type)
    {
    case StructType::Structure:
        UI::TextWrapped("Structure:");
        UI::TextWrapped("Size = " + struct.Size());
        break;
    case StructType::Array:
        UI::TextWrapped("Array:");
        UI::TextWrapped("Size = " + struct.Size());
        break;
    case StructType::Bytes:
        UI::TextWrapped("Bytes:");
        UI::TextWrapped("Size = " + struct.Size());
        break;
    }

    UI::Separator();

    const auto@ children = struct.Children();
    uint relativeOffset = 0;
    for (uint i = 0; i < children.Length; i++)
    {
        UI::PushID("child" + i);

        Struct@ const child = children[i];
        if (UI::Selectable(relativeOffset + ": " + child.Name(), false))
        {
            UI::PopID();

            offsetStack.Add(0);
            structStack.Add(child);
            return;
        }
        relativeOffset += child.Size();

        UI::PopID();
    }

    uint offset = offsetStack[lastIndex];
    for (uint i = 0; i < lastIndex; i++)
    {
        @children = structStack[i].Children();
        Struct@ const next = structStack[i + 1];

        uint upToNext = 0;
        for (uint j = 0; children[j] !is next; j++)
            upToNext += children[j].Size();
        offset += upToNext;
    }

    // anti-overflow measures
    if (state is null || offset >= state.Length || offset + 4 >= state.Length)
    {
        if (spam)
            log("...");
        return;
    }

    int32 value = 0;
    value |= state[offset];
    value |= state[offset + 1] << 8;
    value |= state[offset + 2] << 16;
    value |= state[offset + 3] << 24;

    switch (type)
    {
    case StructType::Bool:
        UI::TextWrapped(value == 0 ? "false" : "true");
        break;
    case StructType::Int:
        UI::TextWrapped("" + value);
        break;
    case StructType::Float:
        UI::TextWrapped("" + I32ToF32(value));
        break;
    }

    if (spam)
    {
        double view;
        if (floatView)
            view = I32ToF32(value);
        else
            view = value;
        log("" + view);
    }
}

void OnRunStep(SimulationManager@ simManager)
{
    @state = enabled ? simManager.SaveState().ToArray() : null;
}

float I32ToF32(int32 value)
{
    // born to shift, forced to wipe
    int32 sign = value >> 31;
    int32 exponent = (value << 1) >> 24;
    int32 mantissa = (value << 9) >> 9;
    return -1.0 ** sign * 2.0 ** (exponent - 127) * ((exponent == 0 ? 0.0 : 1.0) + mantissa / 2.0 ** 23.0);
}

// https://github.com/donadigo/TMInterfaceClientPython/blob/master/tminterface/structs.py

enum StructType
{
    None,

    Structure, Array, Bytes,
    Float, Int, Bool
}

interface Struct
{
    string Name() const;
    StructType Type() const;
    array<Struct@>@ Children();
    uint Size() const;
}

uint SumStructSizes(const array<Struct@>@ const structs)
{
    uint size = 0;
    const uint len = structs.Length;
    for (uint i = 0; i < len; i++)
        size += structs[i].Size();
    return size;
}

mixin class Structure : Struct
{
    StructType Type() const { return StructType::Structure; }
    array<Struct@>@ Children() { return children; }
    uint Size() const { return SumStructSizes(children); }
}

class SimStateData : Structure
{
    string Name() const { return "simulation_state"; }

    private array<Struct@> children =
    { Int32Data("version")                     // 0-4
    , Int32Data("context_mode")                // 4-8
    , Int32Data("flags")                       // 8-12
    , ArrayData("timers", { 53 }, Int32Data()) // 12-224
    , HmsDynaStructData("dyna")                // 224-1648
    , SceneVehicleCarData("scene_mobil")       // 1648-3816
    // there is more after this, but I'm too lazy
    //, ArrayData("simulation_wheels", { 4 }, SimulationWheelData())
    //, BytesData("plug_solid", 68)
    //, BytesData("cmd_buffer_core", 264)
    //, PlayerInfoStructData("player_info")
    };
}

class HmsDynaStructData : Structure
{
    HmsDynaStructData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    private array<Struct@> children =
    { BytesData(268)                           // 0-268
    , HmsDynaStateStructData("previous_state") // 268-448
    , HmsDynaStateStructData("current_state")  // 448-628
    , HmsDynaStateStructData("temp_state")     // 628-808
    , BytesData("rest", 616)                   // 808-1424
    };
}

class HmsDynaStateStructData : Structure
{
    HmsDynaStateStructData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    private array<Struct@> children =
    { ArrayData("quat", { 4 }, Float32Data())                      // 0-16
    , ArrayData("rotation", { 3, 3 }, Float32Data())               // 16-52
    , ArrayData("position", { 3 }, Float32Data())                  // 52-64
    , ArrayData("linear_speed", { 3 }, Float32Data())              // 64-76
    , ArrayData("add_linear_speed", { 3 }, Float32Data())          // 76-88
    , ArrayData("angular_speed", { 3 }, Float32Data())             // 88-100
    , ArrayData("force", { 3 }, Float32Data())                     // 100-112
    , ArrayData("torque", { 3 }, Float32Data())                    // 112-124
    , ArrayData("inverse_inertia_tensor", { 3, 3 }, Float32Data()) // 124-160
    , Float32Data("unknown")                                       // 160-164
    , ArrayData("not_tweaked_linear_speed", { 3 }, Float32Data())  // 164-176
    , Int32Data("owner")                                           // 176-180
    };
}

class SceneVehicleCarData : Structure
{
    SceneVehicleCarData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    private array<Struct@> children =
    { BytesData(76)                                                // 0-76
    , Bool32Data("is_update_async")                                // 76-80
    , Float32Data("input_gas")                                     // 80-84
    , Float32Data("input_brake")                                   // 84-88
    , Float32Data("input_steer")                                   // 88-92
    , BytesData(24)                                                // 92-116
    , Bool32Data("is_light_trials_set")                            // 116-120
    , BytesData(28)                                                // 120-148
    , Int32Data("horn_limit")                                      // 148-152
    , BytesData(12)                                                // 152-164
    , Int32Data("quality")                                         // 164-168
    , BytesData(568)                                               // 168-736
    , Float32Data("max_linear_speed")                              // 736-740
    , Int32Data("gearbox_state")                                   // 740-744
    , Int32Data("block_flags")                                     // 744-748
    , SceneVehicleCarStateData("prev_sync_vehicle_state")          // 748-916
    , SceneVehicleCarStateData("sync_vehicle_state")               // 916-1084
    , SceneVehicleCarStateData("async_vehicle_state")              // 1084-1252
    , SceneVehicleCarStateData("prev_async_vehicle_state")         // 1252-1420
    , BytesData(16)                                                // 1420-1436
    , EngineData("engine")                                         // 1436-1484
    , BytesData(8)                                                 // 1484-1492
    , Bool32Data("has_any_contact (unconfirmed)")                  // 1492-1496
    , Bool32Data("has_any_body_contact (unconfirmed)")             // 1496-1500
    , Bool32Data("has_any_lateral_contact")                        // 1500-1504
    , Int32Data("last_has_any_lateral_contact_time")               // 1504-1508
    , Bool32Data("water_forces_applied")                           // 1508-1512
    , Float32Data("turning_rate")                                  // 1512-1516
    , BytesData(8)                                                 // 1516-1524
    , Float32Data("turbo_boost_factor")                            // 1524-1528
    , Int32Data("last_turbo_type_change_time")                     // 1528-1532
    , Int32Data("last_turbo_time")                                 // 1532-1536
    , Int32Data("turbo_type")                                      // 1536-1540
    , BytesData(4)                                                 // 1540-1544
    , Float32Data("roulette_value")                                // 1544-1548
    , Bool32Data("is_freewheeling")                                // 1548-1552
    , BytesData(4)                                                 // 1552-1556
    , Int32Data("last_ground_contact_time (+2540) (unconfirmed)")  // 1556-1560
    , BytesData(16)                                                // 1560-1576
    , Bool32Data("is_sliding")                                     // 1576-1580
    , Int32Data("last_slide_time (+2540) (unconfirmed)")           // 1580-1584
    , Int32Data("last_slide_start_time (+2540) (unconfirmed)")     // 1584-1588
    , Int32Data("last_slide_duration (unconfirmed)")               // 1588-1592
    , BytesData(68)                                                // 1592-1660
    , Int32Data("wheel_contact_absorb_counter")                    // 1660-1664
    , BytesData(28)                                                // 1664-1692
    , Int32Data("burnout_state")                                   // 1692-1696
    , BytesData(108)                                               // 1696-1804
    , ArrayData("current_local_speed", { 3 }, Float32Data())       // 1804-1816
    , BytesData(256)                                               // 1816-2072
    , ArrayData("total_central_force_added", { 3 }, Float32Data()) // 2072-2084
    , BytesData(32)                                                // 2084-2116
    , Bool32Data("is_rubber_ball")                                 // 2116-2120
    , ArrayData("saved_state", { 4, 3 }, Float32Data())            // 2120-2168
    };
}

class SceneVehicleCarStateData : Structure
{
    SceneVehicleCarStateData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    private array<Struct@> children =
    { Float32Data("speed_forward")  // 0-4
    , Float32Data("speed_sideward") // 4-8
    , Float32Data("input_steer")    // 8-12
    , Float32Data("input_gas")      // 12-16
    , Float32Data("input_brake")    // 16-20
    , Bool32Data("is_turbo")        // 20-24
    , BytesData(104)                // 24-128
    , Float32Data("rpm")            // 128-132
    , BytesData(4)                  // 132-136
    , Int32Data("gearbox_state")    // 136-140
    , BytesData("rest", 28)         // 140-168
    };
}

class EngineData : Structure
{
    EngineData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    private array<Struct@> children =
    { Float32Data("max_rpm")        // 0-4
    , BytesData(16)                 // 4-20
    , Float32Data("braking_factor") // 20-24
    , Float32Data("clamped_rpm")    // 24-28
    , Float32Data("actual_rpm")     // 28-32
    , Float32Data("slide_factor")   // 32-36
    , BytesData(4)                  // 36-40
    , Int32Data("rear_gear")        // 40-44
    , Int32Data("gear")             // 44-48
    };
}

class ArrayData : Struct
{
    ArrayData(const string &in name, const array<uint>@ const dimensions, Struct@ exampleChild)
    {
        this.name = name;
        
        uint size = 1;
        for (uint i = 0; i < dimensions.Length; i++)
            size *= dimensions[i];

        children.Resize(size);
        for (uint i = 0; i < size; i++)
            @children[i] = exampleChild;
    }

    private string name;
    private array<Struct@> children;

    string Name() const { return name; }
    StructType Type() const { return StructType::Array; }
    array<Struct@>@ Children() { return children; }
    uint Size() const { return SumStructSizes(children); }
}

class BytesData : Struct
{
    BytesData(const uint size)
    {
        this.size = size;
    }

    BytesData(const string &in name, const uint size)
    {
        this.name = name;
        this.size = size;
    }

    private string name;
    private uint size;
    private array<Struct@> children;

    string Name() const { return name; }
    StructType Type() const { return StructType::Bytes; }
    array<Struct@>@ Children() { return {}; }
    uint Size() const { return size; }
}

mixin class Field : Struct
{
    string Name() const { return name; }
    array<Struct@>@ Children() { return {}; }
    uint Size() const { return 4; }
}

class Bool32Data : Field
{
    Bool32Data() {}

    Bool32Data(const string &in name)
    {
        this.name = name;
    }

    private string name;

    StructType Type() const { return StructType::Bool; }
}

class Int32Data : Field
{
    Int32Data() {}

    Int32Data(const string &in name, const bool signed = false)
    {
        this.name = name;
        this.signed = signed;
    }

    private string name;
    private bool signed;

    StructType Type() const { return StructType::Int; }
}

class Float32Data : Field
{
    Float32Data() {}

    Float32Data(const string &in name)
    {
        this.name = name;
    }

    private string name;

    StructType Type() const { return StructType::Float; }
}
