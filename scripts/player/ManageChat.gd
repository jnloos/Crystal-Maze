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
		.add_desc("Arbitrtary NPC sends message to chat") \
		.add_param("message", "string") \
		.add_param("speaker", "string") \
		.add_param("gender", "int")
	MCP.add_global_handler(handler)
	print("Registrierte Handler:", MCP._global_handlers.keys())

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
	print("Registrierte Handler when button pressed:", MCP._global_handlers.keys())
	var text = input_field.text.strip_edges()

	__speak_text(text, 0)
	input_field.text = ""
	add_message("Du: " + text, Color.CORNFLOWER_BLUE)

	if text == "" or listeners.is_empty():
		return

	# Prompt vorbereiten
	var prompt := Prompt.new("response").add_param("message", text)
	var builder = AI.create_mcp(prompt)

	# Kontext: Spielertext
	builder.add_context(Context.new("input_text", text))

	# Kontext: alle aktiven NPCs
	var player_controller := Reference.player
	for npc in listeners:
		var dist := npc.dist_to(player_controller)
		var anim := npc.get_current_animation_name()

		var npc_context := Context.new(npc.npc_id, {
			"id": npc.npc_id,
			"name": npc.npc_name,
			"gender": npc.npc_gender,
			"description": npc.npc_description,
			"distance_to_player": snapped(dist, 0.1),
			"current_animation": anim
		})
		builder.add_context(npc_context)
		npc.register_ai_handlers(builder)

	# Anfrage an AI senden
	builder.process_input()

func add_message(msg: String, color: Color):
	if messages_box.get_child_count() >= max_messages:
		for child in messages_box.get_children():
			if child != template_label:
				child.queue_free()
				break
	var label = template_label.duplicate()
	label.visible = true
	label.text = msg
	label.add_theme_color_override("font_color", color)
	messages_box.add_child(label)

func handle_say(message: String, speaker: String, gender: int):
	add_message("%s: %s" % [speaker, message], Color.WHITE)
	__speak_text(message, gender)

func register_listener(npc: BaseNPC) -> void:
	if npc not in listeners:
		listeners.append(npc)
		npc.focus_player()
		__update_listener_label()

func unregister_listener(npc: BaseNPC) -> void:
	if npc in listeners:
		npc.defocus_player()
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
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		input_field.grab_focus()
		input_field.caret_column = input_field.text.length()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
