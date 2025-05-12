extends Node3D

# Camera is attached to a player
var player: Node3D

# Adjust camera position
@export var offset: Vector3 = Vector3(0,0,6)
@export var min_distance: float = 2.0
@export var max_distance: float = 12.0
@export var height: float = 2.5

# Adjust camera interactions
@export var sensitivity: float = 0.005
@export var zoom_speed: float = 1.0
@export var min_pitch: float = deg_to_rad(0)
@export var max_pitch: float = deg_to_rad(60)

# current y-axis angle
var yaw: float = 0.0

# current x-axis angle
var pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	if not player:
		return
	var target_pos = player.global_position
	var dir = Vector3(sin(yaw)*cos(pitch), sin(pitch), cos(yaw)*cos(pitch)).normalized()
	var cam_pos = target_pos + dir*offset.z + Vector3.UP*height
	global_position = global_position.lerp(cam_pos, delta*10)
	look_at(target_pos + Vector3.UP*1.5, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	# Do not move when paused
	if PauseStatus.is_paused():
		return
	
	# Update the current angles
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		pitch = clamp(pitch - event.relative.y * sensitivity, min_pitch, max_pitch)
	
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
