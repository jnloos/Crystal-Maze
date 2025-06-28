extends CharacterBody3D
class_name BaseNPC

var npc_id: String = ""
static var __npc_instance_counter: int = 0

@export var npc_name: String = ""
@export var npc_gender: int = 0
@export var npc_description: String = ""

func init_npc() -> void:
	npc_id = "npc_%d" % __npc_instance_counter
	__npc_instance_counter += 1

func dist_to(node: Node3D) -> float:
	return global_position.distance_to(node.global_position)
