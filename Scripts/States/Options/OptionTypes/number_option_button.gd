extends "res://Scripts/States/Options/OptionTypes/option_button.gd"

var wait_frame : bool

func _process(_delta):
	$ValueEdit.position.x = rect_min_size.x + 30
	$ValueEdit/RightButton.position.x = $ValueEdit/Value.rect_min_size.x + 45
	
	wait_frame = false
	
	if menu.allow_input or !is_selected:
		return
	
	if Input.is_action_pressed("left"):
		$ValueEdit/LeftButton.frame = 1
	else:
		$ValueEdit/LeftButton.frame = 0
	
	if Input.is_action_pressed("right"):
		$ValueEdit/RightButton.frame = 3
	else:
		$ValueEdit/RightButton.frame = 2

func _input(event):
	if menu.allow_input or !is_selected:
		return

	var _value = Settings.get(setting)
	
	var _multi = 1
	
	if event is InputEventKey:
		if _value is float:
			if event.control:
				_multi = 0.1

		if event.shift:
			_multi = 10
	
	if event.is_action_pressed("confirm"):
		menu.allow_input = true
		wait_frame = true
	
	if event.is_action("left"):
		if event.is_pressed():
			change_value(-1 * _multi)
	
	if event.is_action("right"):
		if event.is_pressed():
			change_value(1 * _multi)
			
func change_value(change):
	var _value = Settings.get(setting)
	Settings.set(setting, _value + change)
	
	update_value()

func update_value():
	var _value = Settings.get(setting)
	$ValueEdit/Value.text = str(_value)

func selected():
	if wait_frame:
		return
	
	menu.allow_input = false
