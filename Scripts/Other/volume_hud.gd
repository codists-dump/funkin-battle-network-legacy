extends CanvasLayer

func _ready():
	$VolumeBar.visible = false

func volume_updated():
	update_bars()
	
	$VolumeStream.play()
	
	$VolumeBar.visible = true
	$VolumeBar.rect_position.y = 0
	
	$Timer.start(1)
	$Tween.stop_all()
	
func update_bars():
	for _bar in $VolumeBar/Bars.get_children():
		var _bar_volume = int(_bar.name)
		
		_bar.color = Color("7F7F7F")
		if _bar_volume <= Main.cur_volume:
			_bar.color = Color.white

func _on_Timer_timeout():
	$Tween.interpolate_property($VolumeBar, "rect_position:y", 0, -300, 0.15)
	$Tween.start()

func _on_Tween_tween_completed(_object, _key):
	$VolumeBar.visible = false
