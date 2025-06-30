extends Area3D
class_name InteractionArea

@export var chat_ui_path: NodePath = "../../ChatDisplay"
var chat_ui: Node = null

var listeners: Array[BaseNPC] = []
signal listeners_updated

func _ready():
	Reference.interaction_area = self
	if has_node(chat_ui_path):
		chat_ui = get_node(chat_ui_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("npc") and body is BaseNPC:
		if not listeners.has(body):
			listeners.append(body)
			body.focus_player()
			emit_signal("listeners_updated")
			_send_enter_prompt(body)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("npc") and body is BaseNPC:
		if listeners.has(body):
			body.defocus_player()
			listeners.erase(body)
			emit_signal("listeners_updated")
			# _send_exit_prompt(body)

func _send_enter_prompt(npc: BaseNPC) -> void:
	var prompt := Prompt.new("enter_area") \
		.add_param("name", npc.npc_name) \
		.add_param("id", npc.npc_id)
	var mcp := AI.create_mcp(prompt)

	mcp.add_context(npc.context())
	npc.register_ai_handlers(mcp)

	mcp.process_input()

func _send_exit_prompt(npc: BaseNPC) -> void:
	var prompt := Prompt.new("exit_area") \
		.add_param("name", npc.npc_name) \
		.add_param("id", npc.npc_id)
	var mcp := AI.create_mcp(prompt)

	mcp.add_context(npc.context())
	npc.register_ai_handlers(mcp)

	mcp.process_input()

func get_listeners() -> Array[BaseNPC]:
	return listeners.duplicate()
