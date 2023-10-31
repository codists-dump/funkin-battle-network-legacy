extends "res://Scripts/States/Options/OptionTypes/option_button.gd"

var action : String = "left"
var actions : Array

var wait_frame : bool

var selected_action : int
var editing_action : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	create_inputs()

func _process(_delta):
	$Actions.rect_position.x = rect_min_size.x
	
	wait_frame = false
	
	var i : int = 0
	for _action_node in $Actions.get_children():
		if !menu.allow_input && is_selected:
			_action_node.modulate = Color.black
			
			if i == selected_action:
				_action_node.modulate = Color.white
		else:
			_action_node.modulate = Color.white
			
		i += 1
		
	if menu.allow_input:
		selected_action = 0
		editing_action = false
	
func _input(event):
	if menu.allow_input or !is_selected:
		return
	
	if !editing_action:
		if event.is_action_pressed("confirm"):
			editing_action = true
		
		if event.is_action_pressed("right"):
			selected_action += 1
		if event.is_action_pressed("left"):
			selected_action -= 1
	else:
		if event.is_pressed():
			InputMap.action_erase_event(action, actions[selected_action])
			InputMap.action_add_event(action, event)
			create_inputs()
			
			editing_action = false

func create_inputs():
	for _child in $Actions.get_children():
		_child.queue_free()
	
	var _temp_actions = InputMap.get_action_list(action)
	
	for _action in _temp_actions:
		if _action is InputEventKey:
			var _node = Alphabet.new()
			_node.text = _action.as_text()
			
			$Actions.add_child(_node)
			
			actions.append(_action)

func selected():
	if wait_frame:
		return
	
	menu.allow_input = false
