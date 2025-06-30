extends BaseNPC

var possible_names := [
	"Arwen", "Eowyn", "Galadriel", "Luthien", "Idril", "Melian", "Yavanna", "Elwing"
]

var is_following: bool = false
var is_running: bool = false
var min_distance: float = 2.5

@export var walk_speed: float = 2.0
@export var run_speed: float = 6.0

func _sub_ready() -> void:
	npc_name = possible_names[randi() % possible_names.size()]
	npc_gender = 1
	npc_description = Prompt.new("adventurer").to_str()
	play_idle()

func _sub_process(delta: float) -> void:
	if not is_following or Reference.player == null:
		velocity = Vector3.ZERO
		return

	var player_pos := Reference.player.global_position
	var direction := player_pos - global_position
	direction.y = 0  # Nur horizontale Bewegung

	var distance := direction.length()

	if distance <= min_distance:
		velocity = Vector3.ZERO
		if _locked_mode == "locked" and _current_mode != "idle":
			play_idle()
	else:
		var new_dir := direction.normalized()

		# Lauf-/Geh-Wechsel
		if distance > 6.0 and not is_running:
			is_running = true
			if _locked_mode == "locked" and _current_mode != "run":
				play_run()
		elif distance < 4.0 and is_running:
			is_running = false
			if _locked_mode == "locked" and _current_mode != "walk":
				play_walk()

		var speed := run_speed if is_running else walk_speed
		velocity = new_dir * speed

		# Rotation in Bewegungsrichtung
		if velocity.length() > 0.1:
			var target_rot_y := atan2(-velocity.x, -velocity.z)
			rotation.y = lerp_angle(rotation.y, target_rot_y, delta * 5.0)

	move_and_slide()

func follow_player() -> void:
	if Reference.player == null:
		push_warning("Kein Spieler verfügbar zum Folgen.")
		return
	is_following = true

func unfollow_player() -> void:
	is_following = false
	clear_animation_mode()
	play_idle()

func _sub_register_ai_handlers(mcp: MCP) -> void:
	var suffix := ":" + npc_id

	mcp.add_handler(Handler.new("follow" + suffix, Callable(self, "follow_player")) \
		.add_desc("NPC mit ID '%s' beginnt, den Spieler durch das Labyrinth zu verfolgen." % npc_id))

	mcp.add_handler(Handler.new("unfollow" + suffix, Callable(self, "unfollow_player")) \
		.add_desc("NPC mit ID '%s' hört damit auf, den Spieler zu verfolgen und bleibt stehen." % npc_id))

func _sub_context() -> Dictionary:
	return {
		"is_following_player": is_following
	}
