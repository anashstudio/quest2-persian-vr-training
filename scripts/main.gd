extends Node3D

# آموزش کاربری هدست واقعیت مجازی - Meta Quest 2
# نسخه ساده و کاربردی شبیه First Steps، با تمرکز روی کارکرد واقعی OpenXR.

var xr_interface: XRInterface
var origin: XROrigin3D
var left_controller: XRController3D
var right_controller: XRController3D
var title_label: Label3D
var instruction_label: Label3D
var progress_label: Label3D
var status_label: Label3D
var tool: MeshInstance3D
var tool_home := Vector3(0.75, 1.03, -0.75)
var step := 0
var step_done := false
var previous_trigger := false
var previous_grip := false
var previous_a := false
var previous_b := false
var previous_x := false
var previous_y := false
var previous_thumb_click := false
var previous_thumb := Vector2.ZERO

const STEPS := [
    ["شروع", "برای شروع، Trigger کنترلر راست را یک بار فشار دهید.", "trigger"],
    ["Grip", "دکمه Grip کنترلر راست را فشار دهید.", "grip"],
    ["دکمه A", "دکمه A کنترلر راست را فشار دهید.", "a"],
    ["دکمه B", "دکمه B کنترلر راست را فشار دهید.", "b"],
    ["دکمه X", "دکمه X کنترلر چپ را فشار دهید.", "x"],
    ["دکمه Y", "دکمه Y کنترلر چپ را فشار دهید.", "y"],
    ["حرکت", "Thumbstick کنترلر راست را به هر سمتی حرکت دهید.", "thumb"],
    ["کلیک Thumbstick", "Thumbstick کنترلر راست را به داخل فشار دهید.", "thumb_click"],
    ["گرفتن ابزار", "به ابزار نارنجی نگاه کنید و کنترلر راست را به آن نزدیک کنید؛ سپس Grip را نگه دارید.", "pickup"],
    ["تمرین Trigger", "وقتی ابزار را گرفتید، Trigger را فشار دهید.", "trigger2"],
    ["پایان", "آفرین! اکنون کنترلرهای Quest 2 را می‌شناسید. برای شروع دوباره، Trigger را فشار دهید.", "finish"]
]

func _ready() -> void:
    if not _setup_xr():
        _show_xr_error()
        return
    _build_room()
    _build_ui()
    _create_controllers()
    _create_tool()
    _refresh_step()

func _setup_xr() -> bool:
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface == null:
        push_error("OpenXR interface was not found.")
        return false

    if not xr_interface.is_initialized():
        if not xr_interface.initialize():
            push_error("OpenXR initialization failed.")
            return false

    get_viewport().use_xr = true
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

    origin = XROrigin3D.new()
    origin.name = "XROrigin3D"
    origin.position = Vector3.ZERO
    add_child(origin)

    var camera := XRCamera3D.new()
    camera.name = "XRCamera3D"
    camera.current = true
    origin.add_child(camera)

    print("OpenXR initialized: ", xr_interface.get_name())
    return true

func _show_xr_error() -> void:
    var label := Label3D.new()
    label.text = "OpenXR فعال نشد\nاین APK برای Quest/OpenXR ساخته نشده است."
    label.font_size = 42
    label.pixel_size = 0.002
    label.position = Vector3(0, 1.5, -2.0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)

func _create_controllers() -> void:
    left_controller = XRController3D.new()
    left_controller.name = "LeftHand"
    left_controller.tracker = &"left_hand"
    left_controller.pose = &"grip_pose"
    origin.add_child(left_controller)

    right_controller = XRController3D.new()
    right_controller.name = "RightHand"
    right_controller.tracker = &"right_hand"
    right_controller.pose = &"grip_pose"
    origin.add_child(right_controller)

    _add_controller_visual(left_controller, "کنترلر چپ\nX   Y")
    _add_controller_visual(right_controller, "کنترلر راست\nA   B")

func _add_controller_visual(c: XRController3D, text: String) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.10, 0.18, 0.20)
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.06, 0.07, 0.09)
    mesh.material_override = mat
    c.add_child(mesh)

    var label := Label3D.new()
    label.text = text
    label.font_size = 24
    label.pixel_size = 0.0015
    label.position = Vector3(0, 0.20, 0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    c.add_child(label)

func _build_room() -> void:
    var floor := MeshInstance3D.new()
    var floor_mesh := BoxMesh.new()
    floor_mesh.size = Vector3(5.5, 0.08, 5.5)
    floor.mesh = floor_mesh
    floor.position = Vector3(0, -0.04, 0)
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color(0.11, 0.14, 0.17)
    floor.material_override = floor_mat
    add_child(floor)

    var wall := MeshInstance3D.new()
    var wall_mesh := BoxMesh.new()
    wall_mesh.size = Vector3(5.5, 3.0, 0.1)
    wall.mesh = wall_mesh
    wall.position = Vector3(0, 1.5, -2.4)
    var wall_mat := StandardMaterial3D.new()
    wall_mat.albedo_color = Color(0.035, 0.045, 0.06)
    wall.material_override = wall_mat
    add_child(wall)

    # میز آموزشی
    var desk := MeshInstance3D.new()
    var desk_mesh := BoxMesh.new()
    desk_mesh.size = Vector3(2.7, 0.12, 1.25)
    desk.mesh = desk_mesh
    desk.position = Vector3(0, 0.85, -0.7)
    var desk_mat := StandardMaterial3D.new()
    desk_mat.albedo_color = Color(0.28, 0.20, 0.12)
    desk.material_override = desk_mat
    add_child(desk)

    for x in [-1.15, 1.15]:
        for z in [-1.15, -0.25]:
            var leg := MeshInstance3D.new()
            var leg_mesh := BoxMesh.new()
            leg_mesh.size = Vector3(0.12, 0.85, 0.12)
            leg.mesh = leg_mesh
            leg.position = Vector3(x, 0.42, z)
            leg.material_override = desk_mat
            add_child(leg)

    _add_tool_object(Vector3(-0.75, 1.03, -0.72), "پیچ‌گوشتی")
    _add_tool_object(Vector3(0.0, 1.03, -0.72), "آچار")

    var light := OmniLight3D.new()
    light.omni_range = 8.0
    light.light_energy = 2.4
    light.position = Vector3(0, 2.7, 0)
    add_child(light)

func _add_tool_object(pos: Vector3, text: String) -> void:
    var obj := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.055
    mesh.bottom_radius = 0.055
    mesh.height = 0.40
    obj.mesh = mesh
    obj.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.70, 0.73, 0.78)
    obj.material_override = mat
    add_child(obj)

    var label := Label3D.new()
    label.text = text
    label.font_size = 20
    label.pixel_size = 0.0013
    label.position = pos + Vector3(0, 0.28, 0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)

func _create_tool() -> void:
    tool = MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.12, 0.30, 0.12)
    tool.mesh = mesh
    tool.position = tool_home
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.95, 0.45, 0.05)
    tool.material_override = mat
    add_child(tool)

    var label := Label3D.new()
    label.text = "ابزار تمرین"
    label.font_size = 24
    label.pixel_size = 0.0015
    label.position = tool_home + Vector3(0, 0.24, 0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)

func _build_ui() -> void:
    title_label = _make_label("مرکز منابع یادگیری", Vector3(0, 2.15, -1.75), 52)
    instruction_label = _make_label("", Vector3(0, 1.65, -1.75), 34)
    progress_label = _make_label("", Vector3(0, 1.28, -1.75), 26)
    status_label = _make_label("", Vector3(0, 1.03, -1.75), 24)

func _make_label(text: String, pos: Vector3, size: int) -> Label3D:
    var l := Label3D.new()
    l.text = text
    l.font_size = size
    l.pixel_size = 0.0017
    l.position = pos
    l.modulate = Color(0.95, 0.97, 1.0)
    l.outline_size = 8
    l.outline_modulate = Color(0.01, 0.02, 0.03, 0.95)
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(l)
    return l

func _process(_delta: float) -> void:
    if left_controller == null or right_controller == null:
        return

    var trigger := right_controller.get_float("trigger")
    var grip := right_controller.get_float("grip")
    var a := right_controller.is_button_pressed("ax_button")
    var b := right_controller.is_button_pressed("by_button")
    var x := left_controller.is_button_pressed("ax_button")
    var y := left_controller.is_button_pressed("by_button")
    var thumb_click := right_controller.is_button_pressed("primary_click")
    var thumb := right_controller.get_vector2("primary")

    if step == 0 and trigger > 0.7 and not previous_trigger:
        _complete_step("Trigger درست کار می‌کند.")
    elif step == 1 and grip > 0.7 and not previous_grip:
        _complete_step("Grip درست کار می‌کند.")
    elif step == 2 and a and not previous_a:
        _complete_step("A شناسایی شد.")
    elif step == 3 and b and not previous_b:
        _complete_step("B شناسایی شد.")
    elif step == 4 and x and not previous_x:
        _complete_step("X شناسایی شد.")
    elif step == 5 and y and not previous_y:
        _complete_step("Y شناسایی شد.")
    elif step == 6 and thumb.length() > 0.55 and previous_thumb.length() < 0.3:
        _complete_step("حرکت Thumbstick شناسایی شد.")
    elif step == 7 and thumb_click and not previous_thumb_click:
        _complete_step("کلیک Thumbstick شناسایی شد.")
    elif step == 8:
        var distance := right_controller.global_position.distance_to(tool.global_position)
        if distance < 0.60 and grip > 0.70:
            tool.global_position = right_controller.global_position + Vector3(0, -0.04, -0.12)
            _complete_step("ابزار را گرفتید.")
    elif step == 9 and trigger > 0.7 and not previous_trigger:
        _complete_step("تمرین Trigger کامل شد.")
    elif step == 10 and trigger > 0.7 and not previous_trigger:
        step = 0
        _refresh_step()

    # حرکت آموزشی آزاد با Thumbstick
    if thumb.length() > 0.15 and origin:
        var forward := -origin.transform.basis.z
        var right := origin.transform.basis.x
        var move := (right * thumb.x + forward * thumb.y) * 0.012
        origin.position += Vector3(move.x, 0, move.z)

    previous_trigger = trigger > 0.7
    previous_grip = grip > 0.7
    previous_a = a
    previous_b = b
    previous_x = x
    previous_y = y
    previous_thumb_click = thumb_click
    previous_thumb = thumb

func _complete_step(message: String) -> void:
    if step_done:
        return
    step_done = true
    status_label.text = "✓ " + message
    await get_tree().create_timer(0.8).timeout
    step += 1
    step_done = false
    _refresh_step()

func _refresh_step() -> void:
    var data = STEPS[step]
    title_label.text = "مرکز منابع یادگیری"
    instruction_label.text = data[0] + "\n" + data[1]
    progress_label.text = "مرحله %d از %d" % [step + 1, STEPS.size()]
    status_label.text = ""
