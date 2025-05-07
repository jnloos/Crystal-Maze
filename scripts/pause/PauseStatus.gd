extends Node

signal pause_toggled(paused: bool)
var paused: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		paused = not paused
		# Maus-Cursor umschalten
		if paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		emit_signal("pause_toggled", paused)

func is_paused() -> bool:
	return paused
