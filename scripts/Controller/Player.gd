extends CharacterBody3D

@export var walk_speed := 4.0
@export var run_speed := 8.0
@export var turn_speed := 180.0  # Grad pro Sekunde (nicht vergessen: Umwandlung in Bogenmaß!)

@onready var anim_player = $HeroVisual/AnimationPlayer

var walking := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event.is_action_pressed("toggle_walk"):
		walking = !walking
		if Config.debug:
			print("Walking mode:", walking)

func _physics_process(delta):
	var input_vector = Vector3.ZERO

	# Vorwärts / Rückwärts basierend auf Blickrichtung des Spielers
	if Input.is_action_pressed("move_forward"):
		input_vector -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_vector += transform.basis.z

	# Spieler um eigene Y-Achse drehen (A/D)
	if Input.is_action_pressed("move_left"):
		rotation.y += deg_to_rad(turn_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotation.y -= deg_to_rad(turn_speed * delta)

	# Bewegung anwenden
	input_vector = input_vector.normalized()
	var speed = walk_speed if walking else run_speed
	velocity = input_vector * speed
	move_and_slide()

	# Animationen abhängig von Bewegung
	if input_vector.length() > 0.01:
		var target_anim = "Walk" if walking else "Run"
		if anim_player.current_animation != target_anim:
			anim_player.play(target_anim)
	else:
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")
