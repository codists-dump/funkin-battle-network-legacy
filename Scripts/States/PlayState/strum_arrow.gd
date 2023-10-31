extends Node2D


# The direction this strum button is.
export(Chart.NoteDirs) var note_type = Chart.NoteDirs.LEFT

# The current animation frame (not based on note_type)
export(int) var cur_frame : int


# If the button has been hit by a bot last.
# Used for reseting the hit animation.
var hit_by_bot : bool = false
# If the button is currently held or not.
var pressed = false

var offset = 0

# Godot process event.
func _process(_delta):
	# Set the sprites frame based on note type.
	$Sprite.frame = (note_type * $Sprite.hframes) + cur_frame

# Check for notes on the current button that can be hit.
func detect_note_hit() -> bool:
	for _note in $Notes.get_children():
		if _note.can_hit:
			_note.note_hit()
			
			# shubs duped note check thing
			# (thanks shubs you are awesome)
			# should probably fix this later
			for _duped_note in $Notes.get_children():
				if (_duped_note == _note):
					continue
				
				if (_duped_note.note_type == _note.note_type):
					if (_duped_note.strum_time <= _note.strum_time + 0.01):
						_duped_note.queue_free()
			
			return true
	
	return false

# If the last note was hit by a bot automatically go back to idle on note press.
func _on_AnimationPlayer_animation_finished(_anim_name):
	if !hit_by_bot:
		return
	
	if _anim_name == "hit":
		$AnimationPlayer.play("idle")
