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
	
	if event is InputEventKey:
		if event.is_pressed():
			var _value = Settings.get(setting)
			
			match event.scancode:
				KEY_BACKSPACE:
					_value.erase(len(_value)-1, 1)
					
					change_value(_value)
					
				_:
					var _addon = char(event.unicode)
					var _new_string = _value + _addon
					
					change_value(_new_string)

func change_value(new_string):
	Settings.set(setting, new_string)
	
	update_value()
	
func update_value():
	var _value = Settings.get(setting)
	$Value.text = _value

func selected():
	if wait_frame:
		return
	
	menu.allow_input = false
