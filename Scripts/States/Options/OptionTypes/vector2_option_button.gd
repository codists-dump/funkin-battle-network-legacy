extends "res://Scripts/States/Options/OptionTypes/option_button.gd"

var wait_frame : bool

func _process(_delta):
	$Value.rect_position.x = rect_min_size.x
	
	wait_frame = false
	
func _input(event):
	if menu.allow_input or !is_selected:
		return
		
	if event.is_action_pressed("confirm"):
		menu.allow_input = true
		wait_frame = true
	
	if event.is_pressed():
		var _y_move = int(event.is_action("up")) - int(event.is_action("down"))
		var _x_move = int(event.is_action("right")) - int(event.is_action("left"))
	
		change_value(Vector2(_x_move, _y_move))

func change_value(vector_change):
	var _value = Settings.get(setting)
	Settings.set(setting, _value + vector_change)
	
	update_value()
	
func update_value():
	var _value = Settings.get(setting)
	$Value.text = "X" + str(_value.x) + " Y" + str(_value.y)

func selected():
	if wait_frame:
		return
	
	menu.allow_input = false
