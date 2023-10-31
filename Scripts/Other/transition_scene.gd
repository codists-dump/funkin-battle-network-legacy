extends CanvasLayer

signal transtioned()

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"fade_in":
			emit_signal("transtioned")
			$AnimationPlayer.play("fade_out")
		"fade_out":
			queue_free()
