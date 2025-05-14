# PauseOverlay.gd
extends Control

@onready var label := $Background/Label

func _ready() -> void:
	hide()
	print("▶️ PauseOverlay ready and connected")
	PauseManager.connect("pause_toggled", Callable(self, "_on_pause_toggled"))

func _on_pause_toggled(paused: bool) -> void:
	print("▶️ PauseOverlay got pause_toggled=", paused, " message=", PauseManager.get_message())
	if paused:
		label.text = PauseManager.get_message()
		show()
	else:
		hide()
