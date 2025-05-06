extends Node3D

@onready var player = $Player
@onready var camera_rig = $CameraRig

func _ready():
	camera_rig.set_follow_target(player)
	print("Camera target set to:", player.name)
