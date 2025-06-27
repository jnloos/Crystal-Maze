extends Node
class_name MCP

var handlers: Dictionary = {}
var capabilities: Array = []
var context: Dictionary = {}

@export var openai_path: NodePath = NodePath("OpenAi")
var openai: Node = null
var _current_callback = Callable()

func _ready():
	if openai_path != NodePath(""):
		if has_node(openai_path):
			openai = get_node(openai_path)
		else:
			push_warning("MCP: NodePath not found, attempting fallback scan...")

	if openai == null:
		openai = get_tree().get_root().find_node("OpenAi", true, false)

	if openai:
		openai.connect("gpt_response_completed", Callable(self, "_on_openai_response"))
	else:
		push_error("MCP: OpenAI node not found via path or fallback scan.")

func with_action(name: String, description: String, handler) -> MCP:
	handlers[name] = handler
	capabilities.append({
		"name": name,
		"description": description
	})
	return self

func with_actions(actions: Array) -> MCP:
	for action in actions:
		with_action(action.name, action.description, action.handler)
	return self

func with_context(ctx: Dictionary) -> MCP:
	context = ctx
	return self

func process_input(player_input: String, callback := Callable()) -> MCP:
	if not openai:
		push_error("MCP: No OpenAI node set.")
		return self

	var payload := {
		"prompt": "Player says: '%s'" % player_input,
		"actions": capabilities,
		"context": context
	}

	var json_prompt := JSON.stringify(payload)
	_current_callback = callback

	var msg = Message.new()
	msg.set_content(json_prompt)
	openai.prompt_gpt([msg])
	return self

func _on_openai_response(message: Message, response: Dictionary):
	var content = response.get("choices", [])[0].get("message", {}).get("content", "")
	interpret_response(content)
	if _current_callback.is_valid():
		_current_callback.call_deferred(content)

func interpret_response(json_string: String) -> MCP:
	var result = JSON.new()
	if result.parse(json_string) != OK:
		push_warning("JSON parsing failed: %s" % json_string)
		return self

	var data: Dictionary = result.data
	if not data.has("action"):
		push_warning("Missing 'action' in AI response.")
		return self

	var action = data["action"]
	var reason = data.get("reason", "")

	if handlers.has(action):
		handlers[action].call(data)
		if reason != "":
			print("AI reasoning:", reason)
	else:
		push_warning("Unknown action: %s" % action)

	return self
