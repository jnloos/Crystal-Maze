extends Control
class_name ManageChat

@onready var input_field := $VBoxContainer/LineEdit
@onready var send_button := $VBoxContainer/SendButton
@onready var listener_label := $VBoxContainer/Listeners
@onready var messages_box := $VBoxContainer/Messages
@onready var template_label := messages_box.get_node("Template")

var listeners: Array[BaseNPC] = []
var max_messages: int = 5

func _ready():
	var handler = Handler.new("say", Callable(self, "handle_say")) \
		.add_desc("NPC sends message to chat") \
		.add_param("message", "string") \
		.add_param("speaker", "string") \
		.add_param("gender", "int")
	MCP.add_global_handler(handler)

	send_button.pressed.connect(_on_send_pressed)
	__speak_text("Finde den Schatz! Er muss im Labyrinth versteckt sein!", 0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		var current_focus = get_viewport().gui_get_focus_owner()
		if current_focus == input_field:
			get_viewport().gui_release_focus()
		else:
			input_field.grab_focus()
			input_field.caret_column = input_field.text.length()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("submit_chat"):
		if get_viewport().gui_get_focus_owner() == input_field:
			_on_send_pressed()
			get_viewport().gui_release_focus()
			get_viewport().set_input_as_handled()

func _on_send_pressed():
	var text = input_field.text.strip_edges()
	__speak_text(text, 0)

	if text == "" or listeners.is_empty():
		return
	input_field.text = ""
	add_message("Du: " + text, Color.CORNFLOWER_BLUE)

	# Prompt vorbereiten
	var prompt := Prompt.new("response").add_param("message", text)
	var builder = AI.create_mcp(prompt)

	# Kontext: Spielertext
	builder.add_context(Context.new("input_text", text))

	# Kontext: alle aktiven NPCs
	var player_controller := get_parent()
	for npc in listeners:
		var dist := npc.dist_to(player_controller)
		var npc_context := Context.new("npc_" + npc.npc_name, {
			"speaker": npc.npc_name,
			"gender": npc.npc_gender,
			"description": npc.npc_description,
			"distance_to_player": snapped(dist, 0.1)
		})
		builder.add_context(npc_context)

	# Anfrage an AI senden
	builder.process_input(Callable(self, "on_ai_response"))

func add_message(msg: String, color: Color):
	if messages_box.get_child_count() >= max_messages:
		messages_box.get_child(0).queue_free()
	var label = template_label.duplicate()
	label.visible = true
	label.text = msg
	label.add_theme_color_override("font_color", color)
	messages_box.add_child(label)

func handle_say(data: Dictionary):
	var npc_name: String = data.get("speaker", "NPC")
	var text: String = data.get("message", "[leere Nachricht]")
	var voice: int = data.get("gender", 1)
	add_message("%s: %s" % [npc_name, text], Color.DARK_ORANGE)
	__speak_text(text, voice)

func register_listener(npc: BaseNPC) -> void:
	if npc not in listeners:
		listeners.append(npc)
		__update_listener_label()

func unregister_listener(npc: BaseNPC) -> void:
	if npc in listeners:
		listeners.erase(npc)
		__update_listener_label()

func __update_listener_label():
	if listeners.size() == 0:
		listener_label.text = "Zuhörer: niemand"
	else:
		var names = []
		for npc in listeners:
			names.append(npc.npc_name)
		listener_label.text = "Zuhörer: " + ", ".join(names)

func __speak_text(text: String, gender: int = 1):
	var voice = DisplayServer.tts_get_voices_for_language("en")[gender % 2]
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice)

func _toggle_chat_focus():
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner == input_field:
		input_field.release_focus()
	else:
		input_field.grab_focus()
		
func on_ai_response(content: String) -> void:
	print("GPT antwortet mit:\n", content)

	var result := JSON.new()
	if result.parse(content) != OK:
		push_warning("Antwort konnte nicht als JSON geparst werden.")
		add_message("[Fehlerhafte GPT-Antwort]", Color.WHITE)
		return

	var data = result.data
	if typeof(data) != TYPE_ARRAY:
		push_warning("GPT-Antwort war kein Array.")
		add_message("[Unerwartetes Antwortformat]", Color.RED)
		return

	for item in data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var action: String = item.get("action", "")
		if action == "say":
			handle_say(item)
		else:
			push_warning("Unbekannte Aktion ignoriert: %s" % action)
