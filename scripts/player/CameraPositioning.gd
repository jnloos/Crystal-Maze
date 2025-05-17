extends Node3D

# Camera is attached to a player
var player: Node3D

# Adjust camera position
@export var offset: Vector3 = Vector3(0, 0, 6)
@export var min_distance: float = 2.0
@export var max_distance: float = 12.0
@export var height: float = 2.5

# Adjust camera interactions
@export var sensitivity: float = 0.002
@export var zoom_speed: float = 10.0
@export var min_pitch: float = deg_to_rad(0)
@export var max_pitch: float = deg_to_rad(80)
@export var rot_speed: float = 10.0
@export var follow_speed: float = 10.0

# current y-axis angle
var yaw: float = 0.0

# current x-axis angle
var pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	if not player:
		return

	# 1) Berechne exakte Ziel-Position hinter dem Spieler
	var target_pos: Vector3 = player.global_position
	var dir: Vector3 = Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	).normalized()
	var cam_target: Vector3 = target_pos + dir * offset.z + Vector3.UP * height

	# 2) Sanftes Hinterherfliegen (Position)
	var new_pos: Vector3 = global_position.move_toward(cam_target, follow_speed * delta)

	# 3) Sanfte Rotation (Basis slerp)
	var look_target: Vector3 = target_pos + Vector3.UP * 1.5
	var forward: Vector3 = (look_target - new_pos).normalized()
	var desired_basis: Basis = Basis().looking_at(forward, Vector3.UP)
	var new_basis: Basis = global_transform.basis.slerp(desired_basis, rot_speed * delta)

	# 4) Setze neuen Transform
	global_transform = Transform3D(new_basis, new_pos)

func _unhandled_input(event: InputEvent) -> void:
	# Do not move when paused
	if PauseManager.is_paused():
		return
	
	# Update the current angles without mouse button check
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		pitch = clamp(pitch + event.relative.y * sensitivity, min_pitch, max_pitch)  # Invert pitch here
	
	# Zoom in or out
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			offset.z = max(min_distance, offset.z - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			offset.z = min(max_distance, offset.z + zoom_speed)

func follow_target(target: Node3D) -> void:
	player = target
	var dir = (player.global_position - global_position).normalized()
	yaw = atan2(dir.x, dir.z)
	pitch = asin(dir.y)
