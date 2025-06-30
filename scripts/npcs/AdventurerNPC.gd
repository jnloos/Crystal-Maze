extends BaseNPC

var possible_names := [
	"Arwen", "Eowyn", "Galadriel", "Luthien", "Idril", "Melian", "Yavanna", "Elwing"
]

var trail_queue: Array[Vector3] = []
var trail_delay: float = 0.1
var _trail_timer: float = 0.0
var is_following: bool = false
var min_distance: float = 2.5

@export var walk_speed: float = 2.0
@export var run_speed: float = 6.0
var is_running := false

func _sub_ready() -> void:
	npc_name = possible_names[randi() % possible_names.size()]
	npc_gender = 1
	npc_description = Prompt.new("adventurer").add_param("name", npc_name).to_str()
	play_idle()

func _sub_process(delta: float) -> void:
	if not is_following or Reference.player == null:
		velocity = Vector3.ZERO
		return

	var player_pos := Reference.player.global_position
	var distance := global_position.distance_to(player_pos)

	if distance <= min_distance:
		velocity = Vector3.ZERO
		if _locked_mode == Mode.NONE and _current_mode != Mode.IDLE:
			play_idle()
		move_and_slide()
		return

	_trail_timer += delta
	if _trail_timer >= trail_delay:
		_trail_timer = 0.0
		if trail_queue.size() == 0 or trail_queue[-1].distance_to(player_pos) > 0.5:
			trail_queue.append(player_pos)

	if trail_queue.size() > 0:
		var target_pos := trail_queue[0]
		var direction := target_pos - global_position

		if direction.length() > 0.05:
			var new_dir := direction.normalized()

			if distance > 6.0 and not is_running:
				is_running = true
				if _locked_mode == Mode.NONE and _current_mode != Mode.RUN:
					play_run()
			elif distance < 5.0 and is_running:
				is_running = false
				if _locked_mode == Mode.NONE and _current_mode != Mode.WALK:
					play_walk()

			var follow_speed = run_speed if is_running else walk_speed
			velocity = new_dir * follow_speed

			if velocity.length() > 0.1:
				var target_rot_y = atan2(-velocity.x, -velocity.z)
				var current_rot_y = rotation.y
				rotation.y = lerp_angle(current_rot_y, target_rot_y, delta * 5.0)
		else:
			trail_queue.pop_front()
			velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func follow_player() -> void:
	if Reference.player == null:
		push_warning("Kein Spieler verfügbar zum Folgen.")
		return
	trail_queue.clear()
	_trail_timer = 0.0
	is_following = true

func unfollow_player() -> void:
	is_following = false
	trail_queue.clear()
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
