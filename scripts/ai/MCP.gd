extends RefCounted
class_name MCP

# === GLOBAL
static var _global_handlers: Dictionary = {}
static var _global_capabilities: Array = []
static var _global_contexts: Array[Context] = []

# === INSTANCE
var handlers: Dictionary = {}
var capabilities: Array = []
var context: Array[Context] = []
var prompt: Prompt = null
var wrapper: Prompt = null
var _current_callback = Callable()
var openai: Node = null 
var model: String = "gpt-3.5-turbo"  # <-- NEU

func _init(p: Prompt = null, model_name: String = "gpt-3.5-turbo") -> void:
	wrapper = Prompt.new("wrapper")
	prompt = p
	model = model_name

# === Handler/Capability Management ===
static func add_global_handler(handler: Handler) -> void:
	if handler.get_handler().is_valid():
		_global_handlers[handler.get_name()] = handler.get_handler()
		_global_capabilities.append(handler.to_dict())

func add_handler(handler: Handler) -> MCP:
	if handler.get_handler().is_valid():
		handlers[handler.get_name()] = handler.get_handler()
		capabilities.append(handler.to_dict())
	return self

static func add_global_context(ctx: Context) -> void:
	_global_contexts.append(ctx)

func add_context(ctx: Context) -> MCP:
	context.append(ctx)
	return self

# === AI-Kommunikation ===
func process_input(callback := Callable()) -> MCP:
	if not openai:
		push_error("MCP: No OpenAI node set. Use Intelligence.create_mcp()!")
		return self

	if prompt == null:
		push_error("MCP: No prompt template set.")
		return self

	var ctx_dict := {}
	for c in _global_contexts + context:
		ctx_dict.merge(c.to_dict(), true)

	var all_capabilities := _global_capabilities + capabilities
	var all_handlers := _global_handlers.duplicate()
	all_handlers.merge(handlers, true)

	var action_list: Array = []
	for c in all_capabilities:
		var name: String = c.get("name")
		var desc: String = c.get("description", "")
		var param_obj := {}

		var params: Array = c.get("parameters", [])
		for param in params:
			var pname: String = param.get("name", "")
			var ptype: String = param.get("type", "any")
			param_obj[pname] = ptype

		action_list.append({
			"action": name,
			"parameters": param_obj,
			"description": desc
		})

	var context_lines := []
	for key in ctx_dict.keys():
		context_lines.append("- %s: %s" % [key, str(ctx_dict[key])])
	var context_list := "\n".join(context_lines)

	wrapper.add_params({
		"situation": prompt.to_str(),
		"context_list": context_list,
		"action_list": action_list
	})
	var prompt_text := wrapper.to_str()
	print("[MCP → OpenAI] Final Prompt:\n", prompt_text)

	_current_callback = callback

	var msg := Message.new()
	msg.set_content(prompt_text)

	var messages: Array[Message] = [msg]

	openai.prompt_gpt(messages, model)
	return self

func interpret_response(message: Message, response: Dictionary):
	print("[MCP ← OpenAI] Raw GPT response:\n", JSON.stringify(response, "\t"))

	var interpret_response := func(json_string: String):
		var result = JSON.new()
		if result.parse(json_string) != OK:
			push_warning("JSON parsing failed: %s" % json_string)
			return

		var data = result.data
		if typeof(data) == TYPE_DICTIONARY:
			data = [data]
		elif typeof(data) != TYPE_ARRAY:
			push_warning("Expected array or object in AI response.")
			return

		for entry in data:
			if not entry.has("action"):
				push_warning("Missing 'action' in AI response entry.")
				continue

			var action: String = entry["action"]
			var reason: String = entry.get("reason", "")

			var handler_callable = handlers.get(action, _global_handlers.get(action, null))
			if handler_callable and handler_callable.is_valid():
				var param_defs := []
				for c in capabilities + _global_capabilities:
					if c.get("name", "") == action:
						param_defs = c.get("parameters", [])
						break

				if param_defs.size() > 0:
					var args: Array = []
					for param in param_defs:
						args.append(entry.get(param["name"]))
					handler_callable.callv(args)
				else:
					handler_callable.call(entry)

				if reason != "":
					print("AI reasoning:", reason)
			else:
				push_warning("Unknown action: %s" % action)

	var content = response.get("choices", [])[0].get("message", {}).get("content", "")
	interpret_response.call(content)
	if _current_callback.is_valid():
		_current_callback.call_deferred(content)
