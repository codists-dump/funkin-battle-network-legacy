extends "res://Scripts/States/Options/OptionTypes/option_button.gd"

func _process(_delta):
	$Value.rect_position.x = rect_min_size.x

func update_value():
	var _value = Settings.get(setting)
	$Value.modulate = _value
