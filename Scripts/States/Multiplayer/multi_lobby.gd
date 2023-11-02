extends Control

const HOST_ICON = preload("res://Assets/Sprites/Multiplayer/crown.png")

const SONG_POPUP = preload("res://Scenes/States/Multiplayer/Popups/MultiSongPopup.tscn")
const CHAR_POPUP = preload("res://Scenes/States/Multiplayer/Popups/MultiCharPopup.tscn")

const MULTI_CARD = preload("res://Scenes/States/Multiplayer/Other/MultiCard.tscn")

var rng = RandomNumberGenerator.new()

var diff_strings = ["Easy", "Normal", "Hard"]

var game_data = {}

var ready_players = []

var is_starting = false

var card = null

enum READY_RESULT {OK, NO_SONG}

func _ready():
	name = "Lobby"
	
	rng.randomize()
	
	var _error_player = Multiplayer.connect("updated_player", self, "_updated_player")
	var _error_lobby = Multiplayer.connect("updated_lobby", self, "_updated_lobby")
	var _error_disconnect = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	if !get_tree().is_network_server():
		$panel/container/container/control_container/host_button_container.visible = false
	
	Multiplayer.send_player_info()
	
	Conductor.stop_music()
	
	update_player_shit()
	update_lobby_info()
	
func _process(_delta):
	if name != "Lobby":
		name = "Lobby"
		
	if is_instance_valid(card):
		card.position = get_global_mouse_position() + (Vector2(622, 418) / 2)
		
func _input(event):
	if is_instance_valid(card):
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_RIGHT:
				if !event.pressed:
					card.queue_free()
		
func _unhandled_input(event):
	if event.is_action_pressed("cancel"):
		Multiplayer.leave_game()
	
	if get_tree().is_network_server():
		if event is InputEventKey:
			if event.pressed:
				match event.scancode:
					KEY_1:
						Multiplayer.lobby_info.switch_sides = !Multiplayer.lobby_info.get("switch_sides", false)
						Multiplayer.send_lobby_info()
						
						update_info_label()
		
func reset_player():
	pass

func update_player_list():
	var _player_list = $panel/container/container/player_list
	_player_list.clear()
	
	add_player(get_tree().get_network_unique_id(), Multiplayer.my_info)
	
	for _player in Multiplayer.player_info:
		add_player(_player, Multiplayer.player_info[_player])

func update_info_label():
	var _info_label = $panel/container/container/control_container/info_container/info_label
	_info_label.bbcode_text = ""
	
	var _songs = get_song_list()
	
	var _song_str = "Selected Song(s):"
	for _player in _songs:
		var _song = _songs[_player]
		
		var _song_name = _song["song"]
		_song_name = _song_name.replace("-", " ")
		_song_name = _song_name.capitalize()
		
		var _color = "teal"
		if _player == -1:
			_color = "yellow"
			
		if has_song(_song) != OK:
			_color = "red"
			
		if _song["is_online"]:
			_color = "blue"
		
		_song_str += "[color=%s]\n%s (%s)[/color]" % [_color, _song_name, diff_strings[_song["diff"]]]
	
	if len(_songs) == 0:
		_song_str = "No Song(s) Selected"
	
	_info_label.bbcode_text += _song_str
	
	_info_label.bbcode_text += "\n"
	
	var _character_str = ""
	
	var _characters = {}
	
	var _my_character = Multiplayer.my_info.get("character", {}).get("character", "Default")
	if _my_character != null:
		_characters[-1] = _my_character
	
	for _player_id in Multiplayer.player_info:
		var _player_info = Multiplayer.player_info[_player_id]
		var _character = _player_info.get("character", {}).get("character", "Default")
		
		if _character != null:
			_characters[_player_id] = _character
			
	if len(_characters) > 0:
		_character_str += "\n"
	
	var _i = 0
	for _player in _characters:
		var _character = _characters[_player]
		var _char_name = _character.replace("-", " ")
		_char_name = _char_name.capitalize()
		
		var _prefix = ""
		if _i != 0:
			_prefix = " vs "
		
		var _color = "white"
		if _player == -1:
			_color = "yellow"
		
		_character_str += "%s[color=%s]%s[/color]" % [_prefix, _color, _char_name]
		
		_i += 1
	
	if len(_characters) > 0:
		_character_str += "\n"
		
	_info_label.bbcode_text += _character_str
	
	var _switch_sides = Multiplayer.lobby_info.get("switch_sides", false)
	_info_label.bbcode_text += "\nLobby Settings:"
	_info_label.bbcode_text += "[color=teal]\nSwitched Sides: " + str(_switch_sides) + "[/color]"
	
func get_song_list():
	var _songs = {}
	
	var _my_song = Multiplayer.my_info.get("song", null)
	if _my_song != null:
		_songs[-1] = _my_song
	
	for _player_id in Multiplayer.player_info:
		var _player_info = Multiplayer.player_info[_player_id]
		var _song = _player_info.get("song", null)
		
		if _song != null:
			_songs[_player_id] = _song
	
	return _songs

func add_player(_id, _info):
	var _player_list = $panel/container/container/player_list
	var _icon = null
	
	var _name = _info.get("name", "unnamed")
	
	if _id == 1:
		_icon = HOST_ICON
	
	_player_list.add_item(_name, _icon)
	
func assign_roles():
	var _dict = {}
	
	var _info = get_all_players()
	
	var _idx = 0
	
	if Multiplayer.lobby_info.get("switch_sides", false) == true:
		_idx = 1
	
	for _player in _info:
		_dict[_player] = _idx % 2
		_idx += 1
	
	return _dict
	
func assign_opponents():
	var _dict = {}
	
	var _info = get_all_players()
	
	if len(_info) > 1:
		var _last_id = _info[0]
		
		while len(_info) >= 2:
			var _id1 = _info[0]
			var _id2 = _info[1]
			
			_dict[_id2] = _id1
			_dict[_id1] = _id2
			
			_last_id = _id2
			
			_info.remove(0)
			_info.remove(0)
		
		if len(_info) >= 1:
			while len(_info) >= 1:
				var _id = _info[0]
				_dict[_id] = _last_id
				
				_info.remove(0)
	
	return _dict
	
func has_song(_song_data):
	if !_song_data["is_online"]:
		var _dir = Resources.get_resource_path("res://Assets/Songs/", Mods.songs_folder, _song_data.mod + "/songs/")
		if _dir == null:
			return 1
			
		_dir = _dir.simplify_path() + "/"
		
		var _directory = Directory.new()
		
		var _song_dir = _dir + _song_data.song + "/"
		if !_directory.dir_exists(_song_dir):
			return 2
		
		var _file_dir = _song_dir + _song_data.song + Chart.dif_exts[_song_data.diff] + ".json"
		if !_directory.file_exists(_file_dir):
			return 3
			
		return 0
	else:
		return 0
	
func send_start_game():
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_CONTROL):
		if OS.is_debug_build():
			var DEBUG_MOD = "Ourple Guy"
			var DEBUG_SONG = "bite"
			var DEBUG_DIFF = Chart.Difficulties.HARD
			
			Multiplayer.my_info["song"] = {
				"diff": DEBUG_DIFF,
				"is_online": false, 
				"mod": DEBUG_MOD, 
				"online_repo": Resources.online_repo_address, 
				"song": DEBUG_SONG
			}
		
	var _song_list = get_song_list()
	
	if _song_list.size() == 0:
		Main.create_popup("Noone has selected a song.")
		return
	
	var _selected_index = rng.randi() % _song_list.size()
	var _selected_song = _song_list[_song_list.keys()[_selected_index]]
	
	game_data = {
		"song": _selected_song.get("song"),
		"song_online": _selected_song.get("is_online", false),
		"song_repo": _selected_song.get("online_repo", null),
		"diff": _selected_song.get("diff", 1),
		"mod": _selected_song.get("mod"),
		
		"roles": {},
		"opponents": {},
	}
	
	game_data.roles = assign_roles()
	game_data.opponents = assign_opponents()
	
	print("Attempting to start game...")
	
	var _ready_state = get_ready_state()
	print("My ready state: %s" % _ready_state)
	
	if _ready_state == READY_RESULT.OK:
		is_starting = true
		rpc("ready_to_start")
		check_all_ready()
	else:
		Main.create_popup("Could not start the game.\n"+get_ready_error(_ready_state, "host"))
	
remote func ready_to_start():
	var _id = get_tree().get_rpc_sender_id()
	rpc_id(_id, "got_ready_start", get_ready_state())
	
func get_ready_state():
	for _player in Multiplayer.player_info:
		var _info = Multiplayer.player_info[_player]
		
		var _song = _info.get("song", null)
		
		if _song != null:
			if has_song(_song) != 0:
				return READY_RESULT.NO_SONG
	
	return READY_RESULT.OK
	
remote func got_ready_start(_result):
	var _id = get_tree().get_rpc_sender_id()
	
	print("Got ready info from %s. Result: %s" % [_id, _result])
	
	if !is_starting:
		return
	
	if _result == READY_RESULT.OK:
		ready_players.append(_id)
		check_all_ready()
	else:
		Main.create_popup("Could not start the game.\n"+get_ready_error(_result, _id))
		abort_start()
	
func check_all_ready():
	if len(ready_players) >= len(Multiplayer.player_info):
		start_game(game_data)
		rpc("start_game", game_data)
	
remote func start_game(_game_data):
	print("Starting game...")
	
	var _state = PlayState.new()
	var _my_id = get_tree().get_network_unique_id()
	
	var _dir = ""
	if !_game_data.song_online:
		_dir = Resources.get_resource_path("res://Assets/Songs/", Mods.songs_folder, _game_data.mod)
		if _dir == null:
			return
	else:
		_state.is_song_online = true
		
	_state.multiplayer_game_data = _game_data
	
	_state.song_directory = _dir + "/songs/" + _game_data.song + "/"
	_state.song_name = _game_data.song
	_state.song_difficulty = _game_data.diff
	_state.song_mod = _game_data.mod
	
	if _game_data.has("song_repo"):
		_state.song_repo = _game_data.song_repo
	
	_state.playing_players = get_all_players()
	
	if _game_data.roles[_my_id] == 1:
		_state.is_enemy = true
	
	_state.opponent = _game_data.opponents.get(_my_id, null)
	
	if _state.opponent != null:
		var _opponents_opponent = _game_data.opponents.get(_state.opponent, null)
		if _opponents_opponent != null:
			_state.is_odd_player = _opponents_opponent != _my_id
	
	var _my_character = Multiplayer.my_info.get("character", {})
	var _opponent_character = {}
	
	if _state.opponent != null:
		_opponent_character = Multiplayer.player_info[_state.opponent].get("character", {})
	
	if !_state.is_enemy:
		_state.player_character_name = _my_character
		_state.enemy_character_name = _opponent_character
	else:
		_state.player_character_name = _opponent_character
		_state.enemy_character_name = _my_character
		
	Main.change_scene_transition(_state)
	
	Multiplayer.my_info["song"] = null
	reset_player()
	
func abort_start():
	game_data.clear()
	ready_players.clear()
	
	is_starting = false
	
	print("Could not start the game.")
	
func get_ready_error(_error, _player=null):
	var _prefix = ""
	if _player != null:
		_prefix = " (%s)" % _player
	
	match _error:
		READY_RESULT.NO_SONG:
			return "Player is missing a song." + _prefix

func update_lobby_info():
	update_info_label()

func update_player_shit():
	update_player_list()
	update_info_label()

func _updated_player(_id):
	update_player_shit()
	
func _updated_lobby():
	update_lobby_info()

func _player_disconnected(_id):
	update_player_shit()

func _on_start_button_pressed():
	send_start_game()
	
func _picked_song(_song_data):
	Multiplayer.my_info["song"] = _song_data
	Multiplayer.send_player_info()

func _picked_character(_character):
	Multiplayer.my_info["character"] = _character
	Multiplayer.send_player_info()

func get_all_players():
	var _info = Multiplayer.player_info.keys()
	_info.push_front(get_tree().get_network_unique_id())
	
	return _info

func _on_song_button_pressed():
	var _popup = SONG_POPUP.instance()
	_popup.connect("picked_song", self, "_picked_song")
	
	add_child(_popup)

func _on_char_button_pressed():
	var _popup = CHAR_POPUP.instance()
	_popup.connect("picked_character", self, "_picked_character")
	
	add_child(_popup)

func _on_player_list_item_rmb_selected(_index, _at_position):
	var _player = get_all_players()[_index]
	
	if is_instance_valid(card):
		card.queue_free()
	
	card = MULTI_CARD.instance()
	
	if _player != get_tree().get_network_unique_id():
		var _data = Multiplayer.player_info.get(_player, {})
		card.dict = _data.get("multi_data", {})
	
	card.visible = true
	
	add_child(card)
