tool
extends Sprite

var already_bopped = false

func _process(_delta):
	$Sprite.offset = offset
	$Sprite.frame = frame

func bop():
	if !$AnimationPlayer.is_playing() or already_bopped:
		$AnimationPlayer.stop()
		$AnimationPlayer.play("bop")
		
		already_bopped = true
