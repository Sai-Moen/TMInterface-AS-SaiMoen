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
    floatView = UI::Checkbox("Float View", floatView);
    UI::TextDimmed("Views bytes as floating point values instead of integers (also affects console spam).");

    UI::Separator();

    const uint lastIndex = offsetStack.Length - 1;
    for (uint i = 0; i <= lastIndex; i++)
    {
        UI::PushID("offset" + i);

        UI::TextWrapped(structStack[i].Name());

        UI::BeginDisabled(i != lastIndex);
        offsetStack[i] = UI::InputInt("Offset", offsetStack[i], 4);
        UI::EndDisabled();

        UI::PopID();
    }

    if (lastIndex > 0 && UI::Button("Up one level"))
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

    uint offset = offsetStack[lastIndex];
    for (uint i = 0; i < lastIndex; i++)
    {
        const auto@ nested = structStack[i].Children();
        Struct@ const next = structStack[i + 1];

        uint upToNext = 0;
        for (uint j = 0; nested[j] !is next; j++)
            upToNext += nested[j].Size();
        offset += upToNext;
    }

    // anti-overflow measures
    const uint len = state is null ? 0 : state.Length;
    if (offset >= len || offset + 4 >= len)
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
    case StructType::Bytes:
        if (floatView)
            UI::TextWrapped("Bytes as i32: " + value);
        else
            UI::TextWrapped("Bytes as f32: " + I32ToF32(value));
        break;
    case StructType::Bool:
        UI::TextWrapped(value == 0 ? "False" : "True");
        break;
    case StructType::Int:
        UI::TextWrapped("i32: " + value);
        break;
    case StructType::Float:
        UI::TextWrapped("f32: " + I32ToF32(value));
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

    const auto@ children = struct.Children();
    if (children.IsEmpty())
        return;

    UI::Separator();

    uint relativeOffset = 0;
    for (uint i = 0; i < children.Length; i++)
    {
        Struct@ const child = children[i];
        if (UI::Selectable(relativeOffset + ": " + child.Name(), false))
        {
            offsetStack.Add(0);
            structStack.Add(child);
            return;
        }
        relativeOffset += child.Size();
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
    int32 exponent = (value >> 23) & 0xff;
    int32 mantissa = value & (-1 >> 9);
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
    uint Size() const;
    Struct@ Copy(const uint index) const;
    array<Struct@>@ Children();
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
    uint Size() const { return SumStructSizes(children); }
    array<Struct@>@ Children() { return children; }
}

class SimStateData : Structure
{
    SimStateData() {}

    string Name() const { return "simulation_state"; }

    Struct@ Copy(const uint index) const { return SimStateData(); }

    private array<Struct@> children =
    { Int32Data("version")                                         // 0-4
    , Int32Data("context_mode")                                    // 4-8
    , Int32Data("flags")                                           // 8-12
    , ArrayData("timers", { 53 }, Int32Data())                     // 12-224
    , HmsDynaStructData("dyna")                                    // 224-1648
    , SceneVehicleCarData("scene_mobil")                           // 1648-3816
    , ArrayData("simulation_wheels", { 4 }, SimulationWheelData()) // 3816-6872
    , BytesData("plug_solid", 68)                                  // 6872-6940
    , BytesData("cmd_buffer_core", 264)                            // 6940-7204
    , PlayerInfoStructData("player_info")                          // 7204-8156
    , ArrayData("internal_input_state", { 10 }, CachedInput())     // 8156-8276

    , Event("input_running_event")    // 8276-8284
    , Event("input_finish_event")     // 8284-8292
    , Event("input_accelerate_event") // 8292-8300
    , Event("input_brake_event")      // 8300-8308
    , Event("input_left_event")       // 8308-8316
    , Event("input_right_event")      // 8316-8324
    , Event("input_steer_event")      // 8324-8332
    , Event("input_gas_event")        // 8332-8340

    , Int32Data("num_respawns") // 8340-8344

    // variable size, not bothering with it
    //, CheckpointData("cp_data") // 8344-?
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

    Struct@ Copy(const uint index) const { return HmsDynaStructData(name + index); }

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

    Struct@ Copy(const uint index) const { return HmsDynaStateStructData(name + index); }

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

    Struct@ Copy(const uint index) const { return SceneVehicleCarData(name + index); }

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
    , Int32Data("last_ground_contact_time (+2550) (unconfirmed)")  // 1556-1560
    , BytesData(16)                                                // 1560-1576
    , Bool32Data("is_sliding")                                     // 1576-1580
    , Int32Data("last_slide_time (+2550) (unconfirmed)")           // 1580-1584
    , Int32Data("last_slide_start_time (+2550) (unconfirmed)")     // 1584-1588
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

    Struct@ Copy(const uint index) const { return SceneVehicleCarStateData(name + index); }

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

    Struct@ Copy(const uint index) const { return EngineData(name + index); }

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

class SimulationWheelData : Structure
{
    SimulationWheelData() {}

    SimulationWheelData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    Struct@ Copy(const uint index) const { return SimulationWheelData(name + index); }

    private array<Struct@> children =
    { BytesData(4)                                                       // 0-4
    , Bool32Data("steerable")                                            // 4-8
    , Int32Data("field_8")                                               // 8-12
    , SurfaceHandlerData("surface_handler")                              // 12-112
    , ArrayData("field_112", { 4, 3 }, Float32Data())                    // 112-160
    , Int32Data("field_160")                                             // 160-164
    , Int32Data("field_164")                                             // 164-168
    , ArrayData("offset_from_vehicle", { 3 }, Float32Data())             // 168-180
    , RealTimeStateData("real_time_state")                               // 180-348
    , Int32Data("field_348")                                             // 348-352
    , ArrayData("contact_relative_local_distance", { 3 }, Float32Data()) // 352-364
    , WheelStateData("prev_sync_wheel_state")                            // 364-464
    , WheelStateData("sync_wheel_state")                                 // 464-564
    , WheelStateData("field_564")                                        // 564-664
    , WheelStateData("async_wheel_state")                                // 664-764
    };
}

class SurfaceHandlerData : Structure
{
    SurfaceHandlerData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    Struct@ Copy(const uint index) const { return SurfaceHandlerData(name + index); }

    private array<Struct@> children =
    { BytesData(4)                                   // 0-4
    , ArrayData("unknown", { 4, 3 }, Float32Data())  // 4-52
    , ArrayData("rotation", { 3, 3 }, Float32Data()) // 52-88
    , ArrayData("position", { 3 }, Float32Data())    // 88-100
    };
}

class RealTimeStateData : Structure
{
    RealTimeStateData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    Struct@ Copy(const uint index) const { return RealTimeStateData(name + index); }

    private array<Struct@> children =
    { Float32Data("damper_absorb")                          // 0-4
    , Float32Data("field_4")                                // 4-8
    , Float32Data("field_8")                                // 8-12
    , ArrayData("field_12", { 3, 3 }, Float32Data())        // 12-48
    , ArrayData("field_48", { 3, 3 }, Float32Data())        // 48-84
    , ArrayData("field_84", { 3 }, Float32Data())           // 84-96
    , BytesData(12)                                         // 96-108
    , Float32Data("field_108")                              // 108-112
    , Bool32Data("has_ground_contact")                      // 112-116
    , Int32Data("contact_material_id")                      // 116-120
    , Bool32Data("is_sliding")                              // 120-124
    , ArrayData("relative_rotz_axis", { 3 }, Float32Data()) // 124-136
    , BytesData(4)                                          // 136-140
    , Int32Data("nb_ground_contact")                        // 140-144
    , ArrayData("field_144", { 3 }, Float32Data())          // 144-156
    , BytesData("rest", 12)                                 // 156-168
    };
}

class WheelStateData : Structure
{
    WheelStateData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    Struct@ Copy(const uint index) const { return WheelStateData(name + index); }

    private array<Struct@> children =
    { BytesData("rest", 100)
    };
}

class PlayerInfoStructData : Structure
{
    PlayerInfoStructData(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    Struct@ Copy(const uint index) const { return PlayerInfoStructData(name + index); }

    private array<Struct@> children =
    { BytesData(576)                 // 0-576
    , Int32Data("team")              // 576-580
    , BytesData(100)                 // 580-680
    , Int32Data("prev_race_time")    // 680-684
    , Int32Data("race_start_time")   // 684-688
    , Int32Data("race_time")         // 688-692
    , Int32Data("race_best_time")    // 692-696
    , Int32Data("lap_start_time")    // 696-700
    , Int32Data("lap_time")          // 700-704
    , Int32Data("lap_best_time")     // 704-708
    , Int32Data("min_respawns")      // 708-712
    , Int32Data("nb_completed")      // 712-716
    , Int32Data("max_completed")     // 716-720
    , Int32Data("stunts_score")      // 720-724
    , Int32Data("best_stunts_score") // 724-728
    , Int32Data("cur_checkpoint")    // 728-732
    , Float32Data("average_rank")    // 732-736
    , Int32Data("current_race_rank") // 736-740
    , Int32Data("current_round_rank") // 740-744
    , BytesData(32)                   // 744-776
    , Int32Data("current_time")       // 776-780
    , BytesData(8)                    // 780-788
    , Int32Data("race_state")         // 788-792
    , Int32Data("ready_enum")         // 792-796
    , Int32Data("round_num")          // 796-800
    , Float32Data("offset_current_cp") // 800-804
    , BytesData(12)                    // 804-816
    , Int32Data("cur_lap_cp_count")    // 816-820
    , Int32Data("cur_cp_count")        // 820-824
    , Int32Data("cur_lap")             // 824-828
    , Bool32Data("race_finished")      // 828-832
    , Int32Data("display_speed")       // 832-836
    , Bool32Data("finish_not_passed")  // 836-840
    , BytesData(76)                    // 840-916
    , Int32Data("countdown_time")      // 916-920
    , BytesData("rest", 32)            // 920-952
    };
}

class CachedInput : Structure
{
    CachedInput() {}

    CachedInput(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    Struct@ Copy(const uint index) const { return CachedInput(name + index); }

    private array<Struct@> children =
    { Int32Data("time")
    , Event("event")
    };
}

class Event : Structure
{
    Event(const string &in name)
    {
        this.name = name;
    }

    private string name;
    string Name() const { return name; }

    Struct@ Copy(const uint index) const { return Event(name + index); }

    private array<Struct@> children =
    { Int32Data("time")
    , Int32Data("input_data")
    };
}

// -- primitives --

class ArrayData : Struct
{
    ArrayData(const string &in name, const array<Struct@>@ children)
    {
        this.name = name;
        this.children = children;
    }

    ArrayData(const string &in name, const array<uint>@ const dimensions, Struct@ exampleChild)
    {
        this.name = name;
        
        uint size = 1;
        for (uint i = 0; i < dimensions.Length; i++)
            size *= dimensions[i];

        children.Resize(size);
        for (uint i = 0; i < size; i++)
            @children[i] = exampleChild.Copy(i);
    }

    private string name;
    private array<Struct@> children;

    string Name() const { return name; }
    StructType Type() const { return StructType::Array; }
    uint Size() const { return SumStructSizes(children); }
    Struct@ Copy(const uint index) const { return ArrayData(name + index, children); }
    array<Struct@>@ Children() { return children; }
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
    uint Size() const { return size; }
    Struct@ Copy(const uint index) const { return BytesData(name + index, size); }
    array<Struct@>@ Children() { return {}; }
}

mixin class Field : Struct
{
    string Name() const { return name; }
    uint Size() const { return 4; }
    array<Struct@>@ Children() { return {}; }
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
    Struct@ Copy(const uint index) const { return Bool32Data(name + index); }
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
    Struct@ Copy(const uint index) const { return Int32Data(name + index, signed); }
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
    Struct@ Copy(const uint index) const { return Float32Data(name + index); }
}
