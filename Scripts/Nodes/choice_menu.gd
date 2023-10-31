extends Control
class_name ChoiceMenu, "res://Assets/Other/Editor/choice_menu.png"

signal option_selected(index)
signal option_changed(index)

# The options to use for the menu.
export(Array) var choices
# The spacing between each Alphabet node.
export(Vector2) var spacing = Vector2(20, 155)
# The color to use when a item is not selected.
export(Color) var unselected_color = Color.gray

# The node to use for the choice nodes.
export(PackedScene) var choice_node = Alphabet.new()

# If the choice menu can currently get input.
var allow_input : bool = true

# The currently selected choice.
var selected : int
# The node the Alphabet nodes are stored in.
var alphabet_node : Node

# The sound when you scroll.
var scroll_stream : AudioStream = preload("res://Assets/Sounds/scroll_menu.ogg")
# The audio player for scrolling.
var scroll_player : AudioStreamPlayer

# The last selected choice.
var last_selected : int

# The position the menu is spawned at.
onready var spawn_position : Vector2 = rect_position

# Godot ready function.
func _ready():
	alphabet_node = Node2D.new()
	add_child(alphabet_node)
	
	if choice_node is PackedScene:
		choice_node = choice_node.instance()
	
	create_choices()
	
	scroll_player = AudioStreamPlayer.new()
	scroll_player.stream = scroll_stream
	add_child(scroll_player)
	
# Godot process function.
func _process(_delta):
	var _i = 0
	
	for _choice in alphabet_node.get_children():
		if _i == selected:
			_choice.modulate = Color.white
		else:
			_choice.modulate = unselected_color
		
		# shitty fix
		# TODO: come back to this
		if _i == 0:
			_choice.rect_position.y = 0
		
		_choice.rect_position = lerp(_choice.rect_position, _i * spacing, _delta * 10)
		
		_i += 1
	
	alphabet_node.position = lerp(alphabet_node.position, -(selected * spacing), _delta * 15)
	
# Godot input function.
func _unhandled_input(event):
	if !allow_input:
		return
	
	if event.is_pressed():
		if event.is_action("up"):
			selected -= 1
		
		if event.is_action("down"):
			selected += 1
		
	if event.is_action_pressed("confirm"):
		option_selected()
		
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_WHEEL_UP:
					selected -= 1
				BUTTON_WHEEL_DOWN:
					selected += 1
				BUTTON_LEFT:
					option_selected()
		
	if selected < 0:
		selected = len(choices)-1
	if selected > len(choices)-1:
		selected = 0
		
	if last_selected != selected:
		option_changed()
	
	last_selected = selected
	
# Create the Alphabet objects.
func create_choices() -> void:
	for _existing_choice in alphabet_node.get_children():
		_existing_choice.queue_free()
	
	var _i = 0
	for _choice in choices:
		var _scene = choice_node.duplicate()
		
		_scene.text = _choice
		_scene.name = str(_i)
		_scene.mouse_filter = MOUSE_FILTER_IGNORE
		
		alphabet_node.add_child(_scene)
		
		_i += 1

# Select the current option.
func option_selected():
	emit_signal("option_selected", selected)

# When the option is changed.
func option_changed():
	emit_signal("option_changed", selected)
	
	scroll_player.play()
