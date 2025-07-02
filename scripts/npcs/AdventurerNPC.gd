extends BaseNPC

var possible_names := [
	"Arwen", "Eowyn", "Galadriel", "Luthien", "Idril", "Melian", "Yavanna", "Elwing"
]

var is_following: bool = false
var min_distance: float = 2.5
var _current_movement_state := "idle"

@export var walk_speed: float = 2.0
@export var run_speed: float = 6.0

# Schrittbewegung
var _step_timer := 0.0
var _step_duration := 2.0
var _step_velocity: Vector3 = Vector3.ZERO

func _sub_ready() -> void:
	npc_name = possible_names[randi() % possible_names.size()]
	npc_gender = 1
	npc_description = Prompt.new("adventurer").to_str()
	play_idle_permanent()

func _sub_process(delta: float) -> void:
	if _step_timer > 0.0:
		_step_timer -= delta
		if _step_velocity != Vector3.ZERO:
			velocity = _step_velocity
		else:
			velocity = Vector3.ZERO
	else:
		_step_timer = 0.0
		_step_velocity = Vector3.ZERO

		if not is_following or Reference.player == null:
			velocity = Vector3.ZERO
		else:
			var player_pos := Reference.player.global_position
			var direction := player_pos - global_position
			direction.y = 0

			var distance := direction.length()

			if distance <= min_distance:
				velocity = Vector3.ZERO
			else:
				var new_dir := direction.normalized()
				var speed := run_speed if distance > 6.0 else walk_speed
				velocity = new_dir * speed

				if velocity.length() > 0.1:
					var target_rot_y := atan2(-velocity.x, -velocity.z)
					rotation.y = lerp_angle(rotation.y, target_rot_y, delta * 5.0)

	if not _animation_locked:
		var v_len := velocity.length()

		if v_len < 0.1:
			if _current_mode != idle_animation:
				play_idle_permanent()
		elif v_len < run_speed - 1.0:
			if _current_mode != walk_animation:
				play_walk()
		else:
			if _current_mode != run_animation:
				play_run()

	move_and_slide()

# Schrittmanöver
func step_forward() -> void:
	_step_timer = _step_duration
	_step_velocity = -transform.basis.z.normalized() * walk_speed

func step_back() -> void:
	_step_timer = _step_duration
	_step_velocity = transform.basis.z.normalized() * walk_speed

func step_left() -> void:
	_step_timer = _step_duration
	_step_velocity = -transform.basis.x.normalized() * walk_speed

func step_right() -> void:
	_step_timer = _step_duration
	_step_velocity = transform.basis.x.normalized() * walk_speed

func follow_player() -> void:
	if Reference.player == null:
		push_warning("Kein Spieler verfügbar zum Folgen.")
		return
	is_following = true

func unfollow_player() -> void:
	is_following = false
	clear_animation_mode()
	play_idle_permanent()

func _sub_register_ai_handlers(mcp: MCP) -> void:
	var suffix := ":" + npc_id

	mcp.add_handler(Handler.new("follow" + suffix, Callable(self, "follow_player")) \
		.add_desc("NPC mit ID '%s' beginnt, den Spieler durch das Labyrinth zu verfolgen." % npc_id))

	mcp.add_handler(Handler.new("unfollow" + suffix, Callable(self, "unfollow_player")) \
		.add_desc("NPC mit ID '%s' hört damit auf, den Spieler zu verfolgen und bleibt stehen." % npc_id))

	mcp.add_handler(Handler.new("step_forward" + suffix, Callable(self, "step_forward")) \
		.add_desc("NPC '%s' geht kurz geradeaus." % npc_id))

	mcp.add_handler(Handler.new("step_back" + suffix, Callable(self, "step_back")) \
		.add_desc("NPC '%s' macht einen Schritt zurück." % npc_id))

	mcp.add_handler(Handler.new("step_left" + suffix, Callable(self, "step_left")) \
		.add_desc("NPC '%s' geht kurz nach links." % npc_id))

	mcp.add_handler(Handler.new("step_right" + suffix, Callable(self, "step_right")) \
		.add_desc("NPC '%s' geht kurz nach rechts." % npc_id))

func _sub_context() -> Dictionary:
	return {
		"is_following_player": is_following
	}
