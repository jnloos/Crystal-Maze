extends BaseNPC

@export var detection_message: String = "Player nearby!"
@export var exit_message: String = "Player left the area."
@export var idle_animation: String = "CharacterArmature|Idle_Neutral"
@export var wave_animation: String = "CharacterArmature|Wave"

var possible_names := [
	"Bernadette", "Günther", "Alina", "Otto", "Selma",
	"Rufus", "Elisa", "Dieter", "Lina", "Hugo"
]

func _ready() -> void:
	npc_name = possible_names[randi() % possible_names.size()]
	init_npc()
	play_animation(idle_animation)
	add_to_group("npc")

func play_animation(animation_name: String) -> void:
	var animation_player = $Adventurer/AnimationPlayer
	
	if not animation_player.has_animation(animation_name):
		push_error("Animation not found: " + animation_name)
		return
	
	animation_player.stop()
	animation_player.seek(0, true)
	animation_player.play(animation_name)
	
	if animation_name == wave_animation:
		if not animation_player.is_connected("animation_finished", Callable(self, "_on_wave_finished")):
			animation_player.animation_finished.connect(Callable(self, "_on_wave_finished"))

func _on_wave_finished(anim_name: String) -> void:
	if anim_name == wave_animation:
		play_animation(idle_animation)
