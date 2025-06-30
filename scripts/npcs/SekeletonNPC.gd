extends BaseNPC

var possible_names := ["Knochenbert", "Ribby", "Schädelchen"]

var is_dead := true
var is_resurrecting := false
var auto_die_timeout := 30.0  # Sekunden bis automatischer Tod

@export var sleep_animation: String = "Death_C_Skeletons"
@export var resurrect_animation: String = "Death_C_Skeletons_Resurrect"
@export var pose_animation: String = "Death_C_Pose"

@onready var pivot: Node3D = $Pivot
var _auto_die_timer: float = 0.0

func _sub_ready() -> void:
	npc_name = possible_names[randi() % possible_names.size()]
	npc_gender = 0
	npc_description = Prompt.new("skeleton").to_str()

	is_dead = true
	is_resurrecting = false
	focus_enabled = false
	_auto_die_timer = 0.0

	_turn_towards_pivot()
	play_animation(sleep_animation, "locked")

func _sub_process(delta: float) -> void:
	velocity = Vector3.ZERO

	# automatisches Sterben nach Timeout
	if not is_dead and not is_resurrecting:
		_auto_die_timer += delta
		if _auto_die_timer >= auto_die_timeout:
			die()

func die() -> void:
	if is_dead or is_resurrecting:
		return

	_turn_towards_pivot()

	is_dead = true
	is_resurrecting = false
	focus_enabled = false
	_auto_die_timer = 0.0

	play_animation(sleep_animation, "locked")

func resurrect() -> void:
	if not is_dead or is_resurrecting:
		return

	_turn_towards_pivot()

	is_dead = false
	is_resurrecting = true
	focus_enabled = true
	_auto_die_timer = 0.0

	play_animation(resurrect_animation, "locked")

func play_pose() -> void:
	play_animation(pose_animation, "idle")

func _turn_towards_pivot() -> void:
	if not is_instance_valid(pivot):
		return
	var direction := global_position.direction_to(pivot.global_position)
	direction.y = 0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == resurrect_animation and is_resurrecting:
		is_resurrecting = false
		clear_animation_mode()

func _sub_register_ai_handlers(mcp: MCP) -> void:
	var suffix := ":" + npc_id

	mcp.add_handler(Handler.new("die" + suffix, Callable(self, "die")) \
		.add_desc("Skelett '%s' legt sich ins Grab." % npc_id))

	mcp.add_handler(Handler.new("resurrect" + suffix, Callable(self, "resurrect")) \
		.add_desc("Skelett '%s' steht wieder auf." % npc_id))

func _sub_context() -> Dictionary:
	return {
		"is_dead": is_dead,
		"is_resurrecting": is_resurrecting,
		"auto_die_timer": snapped(_auto_die_timer, 0.1)
	}
