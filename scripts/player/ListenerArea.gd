extends Area3D

@export var chat_ui_path: NodePath = "../../ChatDisplay"
var chat_ui: Node = null

func _ready():
	if has_node(chat_ui_path):
		chat_ui = get_node(chat_ui_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("npc"):
		chat_ui.register_listener(body)

func _on_body_exited(body):
	if body.is_in_group("npc") and chat_ui:
		chat_ui.unregister_listener(body)
