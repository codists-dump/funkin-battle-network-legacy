extends Node
class_name Stage, "res://Assets/Other/Editor/stage.png"

# The node the characters are put in.
# By default puts it in the root of the scene.
export(NodePath) var characters_node

# The position the player is spawned at.
export(Vector2) var player_position
# The position the enemy is spawned at.
export(Vector2) var enemy_position
# The position girlfriend is spawned at.
export(Vector2) var gf_position

# The players character.
var player_character : Character
# The enemys character.
var enemy_character : Character
# The character acting as gf.
var gf_character : Character

# The PlayState the stage is linked to.
# Used to call for info like sections and junk.
var play_state

onready var camera = $Camera

# The zoom the camera should return to after bopping.
onready var return_zoom = $Camera.zoom

var offset_cam = Vector2.ZERO

var cam_unlocked = false

var fake_characters = {}

# Godot ready function.
func _ready():
	create_characters()
	create_fake_characters()
	
	var _on_beat = Conductor.connect("beat_changed", self, "on_beat")
	var _on_hit_any = play_state.connect("note_hit_any", self, "on_note_hit")

# Godot process function.
func _process(_delta):
	if not cam_unlocked:
		if play_state != null:
#			var _focus_on_strum = play_state.player_strum
#			if !play_state.must_hit:
#				_focus_on_strum = play_state.enemy_strum
#
#			var _focus_on
#			_focus_on_strum = play_state.hud.get_node_or_null(_focus_on_strum)
#			if _focus_on_strum != null:
#				_focus_on = _focus_on_strum.character
				
			var _focus_on = player_character
			if !play_state.must_hit:
				_focus_on = enemy_character
			
			if _focus_on != null:
				var _offset = _focus_on.camera_offset
				if _focus_on.flip_x:
					_offset.x = -_offset.x
				
				camera.position = _focus_on.position + _offset
		
		camera.zoom = lerp(camera.zoom, return_zoom, 5 * _delta)
		
		if Settings.cam_movement:
			camera.offset = lerp(camera.offset, offset_cam, 5 * _delta)

# Activates every beat.
func on_beat(_beat : int) -> void:
	if not cam_unlocked:
		if _beat % play_state.hud.bop_mod == 0:
			var _multi = play_state.hud.cam_bop_scale
			camera.zoom = Vector2(return_zoom.x - _multi, return_zoom.y - _multi)

func on_note_hit(_note, _timing):
	if !Settings.cam_movement:
		return
		
	if _note.must_hit == play_state.must_hit:
		var _offset = Vector2.ZERO
		
		match _note.note_type:
			0:
				_offset = Vector2.LEFT
			1:
				_offset = Vector2.DOWN
			2:
				_offset = Vector2.UP
			3:
				_offset = Vector2.RIGHT
				
		offset_cam = _offset * 15

# Get the characters as nodes instead of paths.
func create_characters() -> void:
	characters_node = get_node_or_null(characters_node)
	if characters_node == null:
		characters_node = self
	
	# Load the characters based on the set name in play state.
	player_character = load_character(play_state.player_character_name)
	enemy_character = load_character(play_state.enemy_character_name)
	
	# Set the enemys values.
	enemy_character.position = enemy_position
	
	# Set the players values.
	player_character.position = player_position
	
	# Load GF after the others cuz she isnt so consistent.
	if !enemy_character.girlfriend_position:
		gf_character = load_character(play_state.gf_character_name)
	
		# Set GF's values.
		gf_character.position = gf_position
	else:
		enemy_character.position = gf_position
	
	# Add the characters to the scene.
	if !enemy_character.girlfriend_position:
		characters_node.add_child(gf_character)
	
	characters_node.add_child(enemy_character)
	characters_node.add_child(player_character)
	
	player_character.flip_x = !player_character.flip_x
	
	player_character.created_character()
	enemy_character.created_character()
	gf_character.created_character()
	
	# Set the playstates characters.
	play_state.player_character = player_character
	play_state.enemy_character = enemy_character

func load_character(_character):
	var _char_data = Resources.get_character_data(_character.get("character", "bf"))
	return Resources.load_character(_char_data[0], _char_data[1])

func get_default_character():
	var _char = Resources.load_character(
		"bf",
		"res://Assets/Characters/bf/"
	)
	
	return _char

func create_fake_characters():
	var _my_id = get_tree().get_network_unique_id()
	
	var _players = play_state.playing_players
	
#	_players = []
#	for _fake_player in 100:
#		var _true_faker_player = _fake_player+200000
#		var _side = _true_faker_player%2
#
#		_players.append(_true_faker_player)
#		play_state.multiplayer_game_data.roles[_true_faker_player] = _side
	
	var _i = 0
	var _cur_pos = 1
	for _player in _players:
		if _player == _my_id:
			continue
		if _player == play_state.opponent:
			continue
		
		var _info = Multiplayer.player_info.get(_player, {})
		var _character = _info.get("character", "bf")
		var _role = play_state.multiplayer_game_data.roles.get(_player, 0)
		
		var _char = load_character(_character)
		
		var _offset = 200 * _cur_pos
		var _pos = player_position + Vector2(_offset, 0)
		if _role == 1:
			_pos = enemy_position - Vector2(_offset, 0)
		
		_char.position = _pos
		_char.z_index = -_cur_pos
		
		_char.name = str(_player)
		
		characters_node.add_child(_char)
		
		fake_characters[_player] = _char
		
		if _role == 0:
			_char.flip_x = !_char.flip_x
		
		_char.created_character()
		
		_i += 1
		if _i >= 2:
			_i = 0
			_cur_pos += 1
