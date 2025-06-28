extends Node
class_name Intelligence

@onready var openai := $OpenAi

func create_mcp(prompt: Prompt) -> MCP:
	var mcp := MCP.new(prompt)
	mcp.openai = openai

	var key := load_api_key()
	openai.set_api(key)

	if not openai.is_connected("gpt_response_completed", Callable(mcp, "interpret_response")):
		openai.connect("gpt_response_completed", Callable(mcp, "interpret_response"))

	return mcp

func load_api_key() -> String:
	var file := FileAccess.open("res://auth.txt", FileAccess.READ)
	if file:
		var key = file.get_as_text().strip_edges()
		file.close()
		return key
	else:
		push_warning("⚠️ Could not open auth.txt for OpenAi API key.")
		return ""
