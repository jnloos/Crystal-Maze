extends Control

func _ready() -> void:
	visible = false
	
	# Link visibility with the pause trigger
	PauseStatus.connect("pause_toggled", Callable(self, "_on_pause_toggled"))

func _on_pause_toggled(paused: bool) -> void:
	visible = paused
	if paused:
		grab_focus()
	else:
		release_focus()
