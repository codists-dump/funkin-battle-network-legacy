extends Node2D


# Emitted once a note is hit.
signal note_hit(note, timing)
# Emitted once a note is missed (from passing)
signal note_missed(note)


# The sheet to use for sustain notes.
var sustain_sheet = preload("res://Assets/Sprites/Notes/sustain_sheet.png")


# The timings for each rating.
# [ms, score, percentage]
var hit_timings : Dictionary = {
	"shit": [180, 50, 0.25],
	"bad": [135, 100, 0.50],
	"good": [90, 200, 0.75],
	"sick": [45, 350, 1],
}

# The time the note is to be hit at.
var strum_time : float
# The type of note, left, right, down, etc...
var note_type : int
# How long the note should be held for.
# If its 0 then the note just isnt a sustain.
var sustain_length : float

var note_value : String

# The scroll speed this note moves at.
var scroll_speed : float

# If the note would normally be hit by the enemy or the player.
var must_hit : bool

# If the note is able to be hit.
var can_hit : bool
# If the note is currently being held.
var held : bool
# If the note has already been pressed.
var pressed : bool
# When disabled the note will no longer move.
var move : bool = true
# The timing when the hold note was pressed.
var hold_timing : float
# If the note has already been missed.
var missed : bool

var online_held = false

var is_online = false

# The button this note is hit by.
var button : Node

# Uhhhh... okay so.
# This variable is used to calculate the difference between the actual song
# position and the fake one to make sure the note is always being hit
# around the center.
var fake_pos : float

# The texture for the end of the sustain note.
var sustain_end : ImageTexture

var do_miss : bool = true

var do_hit : bool = true

var do_anim : bool = true

var health = 1.5

var bot_ignore = false

# Godot ready function.
func _ready():
	fake_pos = Conductor.song_position
	
	$Sprite.frame = note_type
	get_sustain_sprites()

# Godot process function.
func _process(_delta):
	fake_pos += _delta * 1000
	
	if abs(Conductor.song_position - fake_pos) >= 100:
		fake_pos = Conductor.song_position
	
	var _online_offset = button.get_parent().offset
	
	var _to_strum_time = (strum_time - fake_pos) + _online_offset
	var _to_real_strum_time = (strum_time - Conductor.song_position)
	
	var _note_scale = button.get_parent().note_scale
	
	# While the note isn't held or its just a not a hold note lol
	if !held:
		# Set the position of the note based on the strum time and scroll speed.
		if move:
			position.y = (_to_strum_time * scroll_speed) * _note_scale
		
		# Check if the note can be hit right now or not.
		var _max_timing = hit_timings[hit_timings.keys()[0]][0]
		if _to_real_strum_time < _max_timing && _to_real_strum_time > -_max_timing:
			can_hit = true
		else:
			can_hit = false
		
		# Check if the note has been missed.
		if _to_real_strum_time < -_max_timing && !missed:
			note_miss()
		
		# Clear the note after a bit, also removed sustain.
		
		
		var _multi = 2
		if _to_real_strum_time < (-_max_timing * _multi) - _online_offset && missed:
			if sustain_length <= 0:
				queue_free()
			else:
				move = false
				sustain_length -= (_delta * 1000)
		
	# While a note is being held.
	else:
		# TODO: CHANGE THIS
		# I DONT LIKE IT, BUT I AM WAYY TO TIRED TO DO ANYTHING ELSE
		# AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		sustain_length -= (_delta * 1000)
		position.y = 0
		
		# Do the funny flash anim on the button.
		var _anim_button = button.get_node("AnimationPlayer")
		_anim_button.play("hit")
		
		# Play the players animation for holds.
		if do_anim:
			if button.get_parent().character != null:
				var _anim_array = button.get_parent().ANIM_ARRAY
				
				button.get_parent().character.play(_anim_array[note_type], 1)
			
		# Once there is no more sustain, kill the note.
		if sustain_length <= 0:
			queue_free()
		
		# When the hold note is released early do this stuff.
		if button.pressed == false && button.get_parent().is_player && !online_held:
			held = false
			strum_time = Conductor.song_position + hold_timing
			
			_anim_button.play("idle")
			
			if sustain_length <= Conductor.step_crochet:
				queue_free()
	
	# Set the lines position to be accurate with the hold note.
	if sustain_length > 0:
		$Line2D.points[1].y = (sustain_length * scroll_speed) * _note_scale
	
	# Hide the note if its being held.
	$Sprite.visible = !held
	
	# Show the note has been missed with a little gray out.
	# Useful for slow speeds.
	if missed:
		if !is_online:
			modulate.a = 0.5
		
	update()
		
func _draw():
	var _pos = $Line2D.points[1]
	var _offset = Vector2(-sustain_end.get_width() / 2.0, 0)
	draw_texture(sustain_end, _pos + _offset, $Line2D.modulate)

# Get the sprite for the hold note.
func get_sustain_sprites():
	# The line texture.
	var _line_image = sustain_sheet.get_data()
	_line_image = _line_image.get_rect(Rect2( Vector2(note_type * 50, 0), Vector2(50, 50) ))
	
	var _line_texture = ImageTexture.new()
	_line_texture.create_from_image(_line_image)
	
	# The sustain end.
	var _end_image = sustain_sheet.get_data()
	_end_image = _end_image.get_rect(Rect2( Vector2(note_type * 50, 60), Vector2(50, 50) ))
	
	sustain_end = ImageTexture.new()
	sustain_end.create_from_image(_end_image)
	
	# Change the texture.
	$Line2D.texture = _line_texture

# The note hit event.
func note_hit() -> void:
	var _timing = strum_time - Conductor.song_position
	emit_signal("note_hit", self, _timing)
	
	pressed = true
	
	if sustain_length <= 0:
		queue_free()
	else:
		held = true
		hold_timing = (strum_time - Conductor.song_position)

# The note miss event.
func note_miss() -> void:
	emit_signal("note_missed", self)
	
	missed = true
