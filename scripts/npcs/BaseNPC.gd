extends CharacterBody3D
class_name BaseNPC

var npc_id: String = ""
static var __npc_instance_counter: int = 0

@export var npc_name: String = ""
@export var npc_gender: int = 0
@export var npc_description: String = ""

@onready var anim_player: AnimationPlayer = $ControllerNpc/AnimationPlayer

# Animation-Namen
@export var idle_animation: String = "CharacterArmature|Idle"
@export var walk_animation: String = "CharacterArmature|Walk"
@export var run_animation: String = "CharacterArmature|Run"
@export var fight_animation: String = "CharacterArmature|Sword_Slash"
@export var wave_animation: String = "CharacterArmature|Wave"
@export var interact_animation: String = "CharacterArmature|Interact"

# Animation-Modi
enum Mode { NONE, IDLE, WALK, RUN, FIGHT, WAVE, INTERACT }
var _current_mode: int = Mode.NONE
var _locked_mode: int = Mode.NONE

# Fokus auf Spieler
var player: Node3D = null
var focus_enabled := false

func _ready() -> void:
	print("Player ref:", Reference.player)
	init_npc()
	anim_player.animation_finished.connect(_on_animation_finished)
	play_idle()
	_sub_ready()

func _process(_delta: float) -> void:
	if focus_enabled and Reference.player:
		_face_player_y_only()

	if _locked_mode != Mode.NONE:
		_sub_process(_delta)
		return
		
	if velocity.length() > 0.01:
		if velocity.length() < 3.0:
			if _current_mode != Mode.WALK:
				play_walk()
		else:
			if _current_mode != Mode.RUN:
				play_run()
	elif _current_mode == Mode.NONE or not anim_player.is_playing():
		play_idle()

	_sub_process(_delta)

func _face_player_y_only() -> void:
	var direction = global_position.direction_to(Reference.player.global_position)
	direction.y = 0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func init_npc() -> void:
	npc_id = "npc_%d" % __npc_instance_counter
	__npc_instance_counter += 1
	add_to_group("npc")

func dist_to(node: Node3D) -> float:
	return global_position.distance_to(node.global_position)

# Fokussteuerung
func focus_player() -> void:
	focus_enabled = true

func defocus_player() -> void:
	focus_enabled = false

# Animationen
func play_animation(anim_name: String, mode: int) -> void:
	if not anim_player.has_animation(anim_name):
		push_warning("NPC '%s': Animation '%s' nicht gefunden." % [npc_name, anim_name])
		return
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
	_current_mode = mode

func play_idle() -> void:
	play_animation(idle_animation, Mode.IDLE)

func play_walk() -> void:
	play_animation(walk_animation, Mode.WALK)

func play_run() -> void:
	play_animation(run_animation, Mode.RUN)

func play_fight() -> void:
	play_animation(fight_animation, Mode.FIGHT)
	_locked_mode = Mode.FIGHT

func play_wave() -> void:
	play_animation(wave_animation, Mode.WAVE)
	_locked_mode = Mode.WAVE

func play_interact() -> void:
	play_animation(interact_animation, Mode.INTERACT)
	_locked_mode = Mode.INTERACT

func _on_animation_finished(anim_name: String) -> void:
	match _locked_mode:
		Mode.FIGHT, Mode.WAVE, Mode.INTERACT:
			_locked_mode = Mode.NONE

func clear_animation_mode() -> void:
	_current_mode = Mode.NONE
	_locked_mode = Mode.NONE

func get_current_animation_name() -> String:
	match _current_mode:
		Mode.IDLE: return "Idle"
		Mode.WALK: return "Walk"
		Mode.RUN: return "Run"
		Mode.FIGHT: return "Fight"
		Mode.WAVE: return "Wave"
		Mode.INTERACT: return "Interact"
		_: return "None"

func register_ai_handlers(mcp: MCP) -> void:
	if mcp == null:
		push_warning("Kann AI-Animationen nicht registrieren: MCP ist null.")
		return
	if npc_id == "":
		push_error("NPC-ID ist leer – init_npc() wurde wahrscheinlich nicht aufgerufen.")
		return

	var suffix := ":" + npc_id

	# Available ai animations
	mcp.add_handler(Handler.new("fight" + suffix, Callable(self, "play_fight")) \
		.add_desc("Spiele Kampf-Animation für NPC mit ID '%s'" % npc_id))

	mcp.add_handler(Handler.new("wave" + suffix, Callable(self, "play_wave")) \
		.add_desc("Spiele Winken-Animation für NPC mit ID '%s'" % npc_id))

	mcp.add_handler(Handler.new("interact" + suffix, Callable(self, "play_interact")) \
		.add_desc("Spiele Interaktionsanimation für NPC mit ID '%s'" % npc_id))

	_sub_register_ai_handlers(mcp)

func to_context() -> Context:
	return Context.new(npc_id, {
		"id": npc_id,
		"name": npc_name,
		"gender": npc_gender,
		"description": npc_description,
		"distance_to_player": snapped(dist_to(Reference.player), 0.1),
		"current_animation": get_current_animation_name()
	})

# Override in subclasses
func _sub_register_ai_handlers(mcp: MCP) -> void:
	pass

# Override in subclasses
func _sub_ready() -> void:
	pass

# Override in subclasses
func _sub_process(_delta: float) -> void:
	pass
