extends Node
class_name FNFScript


enum CHARACTERS {PLAYER, OPPONENT, GIRLFRIEND}


# VARS FOR USE IN SCRIPTS
# Baasically whenever u need to access the hud or smth.


# The PlayState the script is loaded in.
var play_state

# The character the script is loaded in if valid.
var character

# Where the script is located on the system.
var script_path


# The directory the script is located in.
onready var script_directory = Resources.get_parent_directory(script_path)


# The current HUD.
onready var hud = play_state.hud

# The current Stage.
onready var stage = play_state.stage


# The current Camera.
onready var camera = stage.camera


# VARS FOR SCRIPT STUFF
# Stuff the FNFScript class uses for its functions.


# Custom notes.
var custom_notes : Dictionary


# OK SHIT STARTS HERE FR


# Script Setup
func _ready():
	var _step_connect = Conductor.connect("step_changed", self, "_on_step")
	var _beat_connect = Conductor.connect("beat_changed", self, "_on_beat")
	var _playing_connect = Conductor.connect("song_playing", self, "_song_playing")
	
	play_state.connect("song_started", self, "_song_started")
	play_state.connect("song_ended", self, "_song_ended")

	play_state.connect("note_created", self, "_note_created")
	play_state.connect("note_hit", self, "_note_hit")
	play_state.connect("note_hit_any", self, "_note_hit_any")
	play_state.connect("note_missed", self, "_note_missed")
	play_state.connect("note_missed_any", self, "_note_missed_any")
	
	play_state.connect("loaded", self, "_loaded")

	# for helpful funmcitons
	play_state.connect("note_created", self, "_helper_note_created")


# CONFIG
# Use this function to return any resources thay may
# need to be downloaded online for this script to work.
func _get_resources():
	return []


# FUNCTIONS
# Functions that are run when things happen!

# Once all assets have been loaded in play state.
func _loaded():
	pass


# On a new conductor step.
func _on_step(_step):
	pass

# On a new conductor beat.
func _on_beat(_beat):
	pass


# When the current song has been started.
func _song_started():
	pass

# When the current song has begun playing.
# Basically after the countdown.
func _song_playing():
	pass
	
# When the current song has been finished.
func _song_ended():
	pass


# When a note is created this function is called.
# Useful when creating custom note types.
func _note_created(_note):
	pass

# When a note is hit by the player.
func _note_hit(_note, _timing):
	pass

# When a note is hit by ANY player.
func _note_hit_any(_note, _timing):
	pass

# When a note is missed by the player.
func _note_missed(_note):
	pass

# When a note is missed by ANY player.
func _note_missed_any(_note):
	pass


# When a helper tween is started.
func _tween_started(_object, _key):
	pass

# Each step on a helper tween.
func _tween_step(_object, _key, _elapsed, _value):
	pass

# When a helper tween is completed.
func _tween_completed(_object, _key):
	pass


# HELPER FUNCTIONS
# A bunch of function that make things easier!!!!!


# Creates a tween that gets deleted later awesome.
func tween(_object, _property, _initial_value, _final_value, _duration, _trans_type=Tween.TRANS_LINEAR, _ease_type=Tween.EASE_IN, _delay = 0):
	var _tween = Tween.new()

	_tween.connect("tween_started", self, "_tween_started")
	_tween.connect("tween_step", self, "_tween_step")
	_tween.connect("tween_completed", self, "_tween_completed")

	_tween.connect("tween_all_completed", self, "_helper_tween_completed", [_tween])

	_tween.interpolate_property(_object, _property, _initial_value, _final_value, _duration, _trans_type, _ease_type, _delay)
	
	add_child(_tween)
	_tween.start()


# Creates a Sprite from a image.
func new_sprite(_path):
	var _sprite = Sprite.new()
	_sprite.texture = Mods.mod_image(_path)
	
	return _sprite

# Create a Audio Stream.
func new_audio(_path):
	var _audio = Mods.mod_ogg(_path)

	return _audio

# Loads a FNFScript and adds it as a child of this one.
func load_script(_path, _data = {}):
	var _starting_data = {
		"character": character,
	}
	
	for _key in _data:
		_starting_data[_key] = _data[_key]
	
	return play_state.load_script(_path, _starting_data)

# Creates a XML Sprite.
# Note: Dont add .png or .xml to the end of the path.
func new_sprite_xml(_path):
	var _sprite = XMLSprite.new()
	_sprite.xml_path = _path

	return _sprite


# Create a special type of note.
# Do hit means it will do the normal hit stuffs.
# Do miss means it will do the normal miss stuffs.
func new_note_type(_type, _texture, _sustain_texture, _do_hit=true, _do_miss=true, _bot_ignore=false, _hit_timings=null):
	var _data = {
		"texture": _texture,
		"texture_sustain": _sustain_texture,

		"do_hit": _do_hit,
		"do_miss": _do_miss,
		"bot_ignore": _bot_ignore,
	}

	if _hit_timings is Dictionary:
		_data["hit_timings"] = _hit_timings

	custom_notes[_type] = _data


# Gets the character relative to who is playing.
# Example: if your playing as the enemy and you get the player character it'll return the enemy.
func get_relative_character(_character):
	play_state.get_relative_character(_character)


# uhhh h hahh ha hs
# dont use any of these functions :)


# gets rid of a tween after its use
func _helper_tween_completed(_tween):
	_tween.queue_free()

# sets up a create custom note
func _helper_note_created(_note):
	for _note_type in custom_notes:
		if _note.note_value == _note_type:
			var _note_data = custom_notes[_note_type]
			
			_note.get_node("Sprite").texture = _note_data.get("texture", _note.get_node("Sprite").texture)
			_note.sustain_sheet = _note_data.get("texture_sustain", _note.sustain_sheet)

			_note.do_hit = _note_data.get("do_hit", true)
			_note.do_miss = _note_data.get("do_miss", true)
			_note.bot_ignore = _note_data.get("bot_ignore", false)

			_note.hit_timings = _note_data.get("hit_timings", _note.hit_timings)
