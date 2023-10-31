extends "res://Scripts/States/Options/OptionTypes/option_button.gd"

func _ready():
	$AnimationPlayer.advance(10)

func _process(_delta):
	$Sprite.position.x = rect_min_size.x

func selected():
	var _value = Settings.get(setting)
	Settings.set(setting, !_value)
		
	update_value()
		
func update_value():
	var _value = Settings.get(setting)
	
	if _value == true:
		$AnimationPlayer.play("on")
	else:
		$AnimationPlayer.play("off")
