extends Node3D

var player: Node3D = null

@export var offset := Vector3(0, 0, 6)
@export var height := 2.5
@export var sensitivity := 0.005
@export var zoom_speed := 1.0
@export var min_distance := 2.0
@export var max_distance := 12.0

@export var min_pitch := deg_to_rad(-30)
@export var max_pitch := deg_to_rad(45)

var yaw := 0.0
var pitch := 0.0

func set_follow_target(target: Node3D) -> void:
	player = target

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch = clamp(pitch - event.relative.y * sensitivity, min_pitch, max_pitch)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			offset.z = max(min_distance, offset.z - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			offset.z = min(max_distance, offset.z + zoom_speed)

	# ESC-Taste zum Freigeben der Maus
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	# Linksklick zum Erfassen der Maus (nur wenn sie sichtbar ist)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if not player:
		return

	var target_pos = player.global_transform.origin

	var direction = Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	).normalized()

	var cam_pos = target_pos + direction * offset.z + Vector3.UP * height
	global_position = global_position.lerp(cam_pos, delta * 10)

	look_at(target_pos + Vector3.UP * 1.5, Vector3.UP)
