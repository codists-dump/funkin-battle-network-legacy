extends Node
class_name PlayState, "res://Assets/Other/Editor/play_state.png"

# Emitted when the song starts.
signal song_started()
# Emitted when the song ends.
signal song_ended()
# Emitted when the play_state is about to restart.
signal song_restarted()

# When a note is created.
signal note_created(_note)
# When a note is hit.
signal note_hit(_note, _timing)
# When a note is hit by anyone.
signal note_hit_any(_note, _timing)
# When a note is missed.
signal note_missed(_note)
# When a note is missed.
signal note_missed_any(_note)

# ONLINE STUFFS
# warning-ignore:unused_signal
signal online_loaded_songs()
# warning-ignore:unused_signal
signal online_loaded_song_files()
# warning-ignore:unused_signal
signal online_loaded_script_files()
# warning-ignore:unused_signal
signal online_loaded_character_files()

# Emitted once everything has been loaded in.
signal loaded()


enum CHARACTERS {PLAYER, OPPONENT, GF}


# The scene used as the notes.
const NOTE_SCENE = preload("res://Scenes/States/PlayState/Note.tscn")

# The scene to use for the note splashes.
const NOTE_SPLASH = preload("res://Scenes/States/PlayState/NoteSplash.tscn")

# The scene that is created when the game is paused.
const PAUSE_SCENE = preload("res://Scenes/States/PlayState/PauseState.tscn")
# The scene that is created when you game over.
const GAME_OVER_SCENE = preload("res://Scenes/States/PlayState/GameOverState.tscn")

# The sounds that play when you miss.
const MISS_SOUNDS = [
	preload("res://Assets/Sounds/miss_note_1.ogg"),
	preload("res://Assets/Sounds/miss_note_2.ogg"),
	preload("res://Assets/Sounds/miss_note_3.ogg"),
]

# The sound that plays when you hit a note.
const HIT_SOUND = preload("res://Assets/Sounds/hit_sound.ogg")

const HEY_SOUND = preload("res://Assets/Sounds/hey.ogg")

# The scene to use for rating popups.
var rating_scene = preload("res://Scenes/States/PlayState/Rating.tscn")

# Whether or not to start the song as soon as the node is loaded.
export(bool) var start_automatically = false
# Whether or not to change back to the menu when the song ends.
export(bool) var stop_automatically = false
# Whether health should be used at all.
export(bool) var use_health = false

# The current songs directory.
export(String) var song_directory = "res://Assets/Songs/tutorial/"
# The current songs name.
export(String) var song_name = "tutorial"
# The current songs difficulty.
export(Chart.Difficulties) var song_difficulty = 1

var song_mod = "Friday Night Funkin'"
var song_repo = null

# The name of the stage to load.
export(String) var stage_name = "stage"

# The song data currently being used.
var cur_chart : SongData

# Audio streams.
var inst_stream : AudioStream
var vocal_stream : AudioStream

# Sound effect streams.
var miss_stream : AudioStreamPlayer
var hitsound_stream : AudioStreamPlayer
var hey_stream : AudioStreamPlayer

# The strums to use when creating the notes.
var player_strum : StrumLine setget ,get_player_strum
var enemy_strum : StrumLine setget ,get_enemy_strum

# Character nodes.
var player_character : Character setget ,get_player_character
var enemy_character : Character setget ,get_enemy_character

# The data to use for loading the players character.
var player_character_name = {}
# The data to use for loading the enemys character
var enemy_character_name = {}
# The data to use for loading gfs character.
var gf_character_name = {"character": "gf"}

# Hud node.
var hud : Node
# Stage node.
var stage : Stage

# Whether the current section is a must hit one or not.
# Usually used for controlling the camera.
var must_hit : bool

# Player stats.
# The amount of notes the player has hit in total.
var hit_notes : int
# The amount of notes the player has missed, this does not count note spam.
var missed_notes : int
# The amount of notes the player has missed just from note spam.
var fake_missed_notes : int
# The sum of all hit notes accuracy.
var accuracy_sum : float
# The amount of notes hit in a row without missing.
var combo : int
# Current health value, from 0 to 100
var health : float = 50
# Current score.
var score : int
# Stores the amount of each rating you got.
var hit_ratings : Dictionary

var do_hey : bool

# The average hit timing awesome
var timing_sum = 0

var ready_players = []

var finished_players = []

var finished = false

var playing_players = []

var is_enemy = false

var opponent = null

var player_hits = {}

var player_data = {}

var is_solo = false

var is_team = false

var is_odd_player = false

var multiplayer_game_data = {}

var started = false

var is_song_online = false

var loading_online = false

var files_downloading = {}

var script_resources = []

onready var mod_directory = Resources.get_resource_path("res://Assets/Songs/", Mods.songs_folder, song_mod)

# Godot ready function.
func _ready():
	name = "PlayState"
	
	var _error_disconnected = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	if opponent == null:
		is_solo = true
	if len(playing_players) >= 3:
		is_team = true
	
	load_song(song_directory, song_name, song_difficulty)
	
	ready_stage()
	ready_hud()
	
	load_scripts()
	
	if not is_solo:
		hud.show_waiting()
	
	create_stream_players()
	
	load_online_resources()
	if not loading_online:
		finished_loading()
	
	var _connect_beat = Conductor.connect("beat_changed", self, "_on_beat")

# Godot process function.
func _process(_delta):
	if name != "PlayState":
		name = "PlayState"
	
	if cur_chart == null:
		return
	
	get_section()
	spawn_notes()

	health = clamp(health, 0, 100)
	if health <= 0 and use_health:
		game_over()
		
	song_end_check()
	
	online_hit_check()

# Godot input event.
func _unhandled_input(event):
	var _strum = player_strum
	if is_enemy:
		_strum = enemy_strum
	
	# input
	strum_input(_strum, event)
	
	# taunt
	if event.is_action_pressed("taunt"):
		if event.is_pressed():
			do_hey = true
			
			if event.shift:
				start_hey_anim(true)
	
	# pause
	if event.is_action_pressed("confirm"):
		if event.is_pressed() && !event.alt:
			pause()
		
func online_hit_check():
	for _player in player_hits:
		var _player_array = player_hits[_player]
		for _notes in _player_array:
			var _hit_time = _notes[0]
			var _strum_time = _notes[1]
			var _is_enemy = _notes[2]
			
			var _timing = _strum_time - _hit_time
			
			if Conductor.song_position > _hit_time:
				_player_array.erase(_notes)
				
				var _note = get_note_from_ms(_strum_time, _is_enemy)
				
				if _note == null:
					return
				
				_note.button.hit_by_bot = true
				_note.button.get_node("AnimationPlayer").play("hit")
				
				note_hit(_note, _timing, true)
				
				if _note.sustain_length <= 0:
					_note.queue_free()
				else:
					_note.online_held = true
					_note.held = true
					_note.hold_timing = _timing
	
func get_note_from_ms(_ms, _is_enemy):
	var _strum = player_strum
	if _is_enemy:
		_strum = enemy_strum
	
	for _button in _strum.get_children():
		for _note in _button.get_node("Notes").get_children():
			if _note.strum_time == _ms:
				return _note
				
	return null

# Check for strum input.
func strum_input(_strum_line : StrumLine, _input_event : InputEvent):
	var _action_type = 0
	
	# Test each key.
	for _action in _strum_line.BUTTON_ACTIONS:
		# When the action is presse get the corresponding buttons.
		if _input_event.is_action_pressed(_action):
			for _button in _strum_line.get_children():
				if _button.note_type == _action_type:
					button_pressed(_button)
		
		if _input_event.is_action_released(_action):
			for _button in _strum_line.get_children():
				if _button.note_type == _action_type:
					button_released(_button)
		
		_action_type += 1

# When a strum button is pressed do this.
func button_pressed(_button : Node) -> void:
	var _anim = _button.get_node("AnimationPlayer")
	var _hit = _button.detect_note_hit()
	
	_button.hit_by_bot = false
	
	_button.pressed = true
	
	if _hit:
		_anim.play("hit")
	else:
		_anim.play("pressed")
		
#		if !Settings.ghost_tapping:
#			on_miss(_button)
		
# When a strum button is released do this.
func button_released(_button : Node) -> void:
	var _anim = _button.get_node("AnimationPlayer")
	_anim.play("idle")
	
	_button.pressed = false

# Start the song by loading the chart and playing the music.
func start_song() -> void:
	Conductor.play_song(inst_stream, vocal_stream, cur_chart.bpm, 5)
	emit_signal("song_started")

# Load a songs chart and music.
func load_song(_directory : String, _song_name : String, _song_dif : int) -> void:
	var _file_name = _song_name + Chart.dif_exts[_song_dif] + ".json"
	_directory = _directory.simplify_path() + "/"
	
	# Load the chart.
	if cur_chart == null:
		cur_chart = SongData.new()
		var _error = cur_chart.load_chart(_directory, _file_name)
		
	# Load character.
#	if player_character_name == "":
#		if Resources.get_resource_path("res://Assets/Characters/", Mods.characters_folder, cur_chart.bf) != null:
#			player_character_name = cur_chart.bf
#		else:
#			player_character_name = "bf"
#
#	if enemy_character_name == "":
#		if Resources.get_resource_path("res://Assets/Characters/", Mods.characters_folder, cur_chart.enemy) != null:
#			enemy_character_name = cur_chart.enemy
#		else:
#			enemy_character_name = "bf"
			
	# Load the audio.
	if inst_stream == null:
		inst_stream = Mods.mod_ogg(cur_chart.song_dir + "Inst.ogg")
	
	if vocal_stream == null:
		if cur_chart.use_voices:
			vocal_stream = Mods.mod_ogg(cur_chart.song_dir + "Voices.ogg")
			
	Conductor.reset_music()

func load_online_resources():
	# Remove temp folder.
	var _dir_instance = Directory.new()
	var _file_instance = File.new()
	
	# Delete all temp files.
	var _temp_dir = Resources.iterate_in_directory_all(Resources.temp_online_folder)
	for _dir in _temp_dir:
		var _files = _temp_dir[_dir]
		for _file in _files:
			var _is_folder = _files[_file]
			
			if _is_folder == false:
				_dir_instance.remove(_dir + "/" + _file)
	
	# Load the online song.
	if is_song_online:
		loading_online = true
		yield(load_online_song(), "completed")
	
	# Load custom characters.
	var _player_info = Multiplayer.player_info.keys()
	_player_info.push_front(get_tree().get_network_unique_id())
	
	for _player in _player_info:
		var _character = {}
		if get_tree().get_network_unique_id() != _player:
			_character = Multiplayer.player_info[_player].get("character", {})
		else:
			_character = Multiplayer.my_info.get("character", {})
		
		if _character.get("is_online", false):
			loading_online = true
			yield(load_online_character(_character, _player), "completed")
	
	# Load script resources.
	# Remove any that exist locally.
	if not is_song_online:
		print("Removing anything from download queue that exists locally.")
		
		var download_globally = []
		for resource in script_resources:
			if not _file_instance.file_exists(Mods.mods_folder + resource):
				download_globally.append(resource)
		
		script_resources = download_globally
	
	if len(script_resources) > 0:
		# Load anything that might be needed by the song.
		loading_online = true
		yield(load_online_script_resources(), "completed")
	
	# Ready up after finishing.
	hud.show_waiting()
	
	if loading_online:
		finished_loading()

func load_online_song():
	var _downloading_message = "Downloading %s..." % song_name
	
	var _http = HTTPRequest.new()
	add_child(_http)
	
	var _mod_path = Resources.get_github_raw_content_path(
		song_repo,
		"mods/%s/" % song_mod
	)
	var _song_path = _mod_path + "songs/%s/" % song_name
	#Resources.online_repo_address+"/mods/%s/songs/%s" % [song_mod, song_name]
	
	# GET THE CHART
	#mods/<mod>/songs/criminal/criminal-hard.json
	var _chart_result
	var _done_starting_diff = false
	
	for _diff_index in len(Chart.dif_exts) + 1:
		var _real_diff_index = (len(Chart.dif_exts) - _diff_index) - 1
		
		if not _done_starting_diff:
			_real_diff_index = song_difficulty
			_done_starting_diff = true
		elif _real_diff_index == song_difficulty:
			continue
		
		var _dif_ext = Chart.dif_exts[_real_diff_index]
		var _chart_path = _song_path+"%s%s.json" % [song_name, _dif_ext]
		_chart_path = _chart_path.replace(" ", "%20")
		
		print("Loading online chart %s..." % _chart_path)
		hud.show_waiting(_downloading_message+"\nGetting chart (1/3)")
		
		var _error_chart = _http.request(_chart_path)
		if _error_chart != OK:
			print("error %s" % _error_chart)
			continue
		
		_chart_result = yield(_http, "request_completed")
		if _chart_result[1] != 200:
			print("error2 %s" % _chart_result[1])
			continue
		
		song_difficulty = _real_diff_index
		break
	
	if _chart_result == null:
		return
	
	var _chart_content = parse_json(_chart_result[3].get_string_from_utf8())
	
	if _chart_content == null:
		return
	
	cur_chart = SongData.new()
	var _error = cur_chart.load_chart_data(_chart_content)
	
	_http.queue_free()
	
	# GET THE INST and VOCALS
	var _inst_path = _song_path+"Inst.ogg"
	_inst_path = _inst_path.replace(" ", "%20")
	
	var _vocal_path = _song_path+"Voices.ogg"
	_vocal_path = _vocal_path.replace(" ", "%20")
	
	hud.show_waiting(_downloading_message+"\nGetting Instrumental (2/3)")
	load_online_music(_inst_path)
	
	if cur_chart.use_voices:
		hud.show_waiting(_downloading_message+"\nGetting Voices (3/3)")
		load_online_music(_vocal_path, true)
	
	yield(self, "online_loaded_songs")
	
	if inst_stream.data.empty():
		inst_stream = null
	if vocal_stream.data.empty():
		vocal_stream = null
	
	# additional files
	print("Loading Additional Files...")
	
	var _queued_files = [
		"script.gd", 
		"songs/%s/script.gd" % song_name,
		"stages/%s.gd" % cur_chart.stage
	]
	var _downloaded_files = []
	while len(_queued_files) > 0:
		var _file_name = _queued_files[0]
		
		var _file_path = _mod_path + _file_name
		_file_path = _file_path.replace(" ", "%20")
		
		hud.show_waiting(_downloading_message+"\nDownloading additional files (%s)... (%s)" % [_file_name, len(_queued_files)])
		
		print("Loading " + _file_path + "...")
		
		var _save_path = Resources.temp_online_folder + "mods/%s/" % song_mod + _file_name
		
		load_online_file(_file_path, _save_path, "online_loaded_song_files")
		_downloaded_files.append(_save_path)
				
		_queued_files.remove(0)
	
	yield(self, "online_loaded_song_files")
	
	for _file in _downloaded_files:
		if _file.ends_with(".gd"):
			load_script(_file)
	
func load_online_file(_path, _save_path, _signal = null):
	if _signal != null:
		if files_downloading.get(_signal) == null:
			files_downloading[_signal] = []
		
		files_downloading[_signal].append(_path)
	
	var _http = HTTPRequest.new()
	add_child(_http)
	
	var _exists_file = File.new()
	if not _exists_file.file_exists(_save_path):
		var _error = _http.request(_path)
		if _error == OK:
			var _result = yield(_http, "request_completed")
			if _result[1] == 200:
				var _data = _result[3]
					
				var _start_path = _save_path.rsplit("/", true, 1)
				
				var _directory = Directory.new()
				var _dir_error = _directory.make_dir_recursive(_start_path[0])
				if _dir_error == OK:
					var _file = File.new()
					var _open_error = _file.open(_save_path, File.WRITE)
					if _open_error == OK:
						_file.store_buffer(_data)
						_file.close()
#		else:
#			print("error2 %s" % _result[1])
#	else:
#		print("error1 %s" % _error)
	
	_http.queue_free()
	
	if _signal != null:
		files_downloading[_signal].erase(_path)
		
		if files_downloading[_signal].empty():
			emit_signal(_signal)
	
func load_online_music(_path, _is_vocals = false):
	var _http = HTTPRequest.new()
	add_child(_http)
	
	var _good_data = true
	
	var _error = _http.request(_path)
	if _error != OK:
		print("error %s" % _error)
		_good_data = false
	
	var _result = yield(_http, "request_completed")
	if _result[1] != 200:
		print("error2 %s" % _result[1])
		_good_data = false
	
	var _a = AudioStreamOGGVorbis.new()
	if _good_data:
		_a.data = _result[3]
	
	_http.queue_free()
	
	if not _is_vocals:
		inst_stream = _a
	else:
		vocal_stream = _a
	
	if inst_stream != null and vocal_stream != null:
		emit_signal("online_loaded_songs")
	
func load_online_character(_character, _id):
	var _old_char_node = get_character_from_id(_id)
	_old_char_node.modulate.a = 0.5
	
	var _char_name = _character.get("character", null)
	if _char_name == null:
		return
		
	var _downloading_message = "Downloading character %s..." % _char_name
		
	var _char_repo = _character.get("online_repo", null)
	if _char_repo == null:
		return
	
	var _char_path = Resources.get_github_raw_content_path(
		_char_repo,
		"characters/%s/" % _char_name
	)
	
	var _char_save_path = Resources.temp_online_folder + "characters/%s/" % _char_name
	
	var _queued_files = [
		"icon-%s.png" % _char_name, 
		"%s.json" % _char_name,
		"%s.png" % _char_name,
		"%s.xml" % _char_name,
		
		"emote.ogg",
		"script.gd",
	]
	var _downloaded_files = []
	
	while len(_queued_files) > 0:
		var _file_name = _queued_files[0]
		
		var _file_path = _char_path + _file_name
		_file_path = _file_path.replace(" ", "%20")
		
		print("Loading " + _file_path + "...")
		hud.show_waiting(_downloading_message+"\nDownloading %s... (%s)" % [_file_name, len(_queued_files)])
		
		var _save_path = _char_save_path + _file_name
			
		load_online_file(_file_path, _save_path, "online_loaded_character_files")
		_downloaded_files.append(_save_path)
			
		_queued_files.remove(0)
	
	yield(self, "online_loaded_character_files")
	
	var _char_node = Resources.load_character(_char_name, _char_save_path)
	_old_char_node.get_parent().add_child(_char_node, true)
	
	var _old_name = _old_char_node.name
	_old_char_node.name = "exiting"
	_char_node.name = _old_name
	
	if _old_char_node == player_character:
		stage.player_character = _char_node
		player_character = stage.player_character
		player_strum.character = player_character
		
		_char_node.position = stage.player_position
		_char_node.flip_x = !_char_node.flip_x
	elif _old_char_node == enemy_character:
		stage.enemy_character = _char_node
		enemy_character = stage.enemy_character
		enemy_strum.character = enemy_character
		
		_char_node.position = stage.enemy_position
	elif _old_char_node == stage.fake_characters[_id]:
		stage.fake_characters[_id] = _char_node

		if multiplayer_game_data.roles.get(_id, 0) == 0:
			_char_node.flip_x = !_char_node.flip_x
		
		_char_node.position = _old_char_node.spawn_position
		_char_node.z_index = _old_char_node.z_index
	
	hud.update_health_icons()
	_char_node.created_character()
	
	_old_char_node.queue_free()
	
	var script_exists = false
	for _script in get_tree().get_nodes_in_group("_scripts"):
		if _script.character == _old_char_node:
			_script.character = _char_node
			script_exists = true
	
	if not script_exists:
		for _file in _downloaded_files:
			if _file.ends_with(".gd"):
				load_script(_file, {"character": _char_node})

func load_online_script_resources():
	var _mod_path = Resources.get_github_raw_content_path(
		song_repo,
		""
	)
	
	var _downloading_message = "Downloading script resources..."
	
	var _downloaded_files = []
	
	while len(script_resources) > 0:
		var _file_name = script_resources[0]
		
		var _file_path = _mod_path + _file_name
		_file_path = _file_path.replace(" ", "%20")
		
		print("Loading " + _file_path + "...")
		hud.show_waiting(_downloading_message+"\nDownloading %s... (%s)" % [_file_name, len(script_resources)])
		
		var _save_path = Resources.temp_online_folder + _file_name
			
		load_online_file(_file_path, _save_path, "online_loaded_script_files")
		_downloaded_files.append(_save_path)
			
		script_resources.remove(0)
	
	yield(self, "online_loaded_script_files")

# Get the node for the characters.
func ready_stage() -> void:
	stage = load(Resources.stages[stage_name]).instance()
	
	if stage != null:
		stage.play_state = self
	
	add_child(stage)
	
# Effectivley links the HUD with the PlayState
# Used for getting the strums and stuff, the HUD always take priority.
func ready_hud() -> void:
	hud = load("res://Scenes/States/PlayState/HUD.tscn").instance()
	
	if hud != null:
		hud.play_state = self
		
		player_strum = hud.get_node_or_null(hud.player_strum)
		enemy_strum = hud.get_node_or_null(hud.enemy_strum)
		
		player_strum.character = player_character
		enemy_strum.character = enemy_character
		
		var _strum = enemy_strum
		if is_enemy:
			_strum = player_strum
		
		if is_solo:
			_strum.is_player = false
		
		hud.update_health_icons()
	
	var _canvas = CanvasLayer.new()
	add_child(_canvas)
	
	_canvas.add_child(hud)

# Spawn the next notes in order of strum position.
func spawn_notes() -> void:
	if len(cur_chart.notes) <= 0:
		return
	if !started:
		return
	
	var _next_note = cur_chart.notes[0]
	
	if (_next_note[0] - Conductor.song_position) < ((Conductor.step_crochet / cur_chart.scroll_speed) * 24):
		spawn_note(_next_note)
		
		cur_chart.notes.remove(0)

# Create the note object itself.
func spawn_note(_note_data : Array) -> void:
	var _strum = player_strum
	var _must_hit = true
	
	if (_note_data[1] >= len(Chart.NoteDirs)):
		_strum = enemy_strum
		_note_data[1] -= len(Chart.NoteDirs)
		_must_hit = false
		
#	if len(_note_data) >= 4:
#		return
	
	var _is_online = false
	
	if !is_enemy && _strum == enemy_strum:
		_is_online = true
	if is_enemy && _strum == player_strum:
		_is_online = true
	
	if (_strum == null):
		return
	
	var _scene = NOTE_SCENE.instance()
	
	_scene.strum_time = _note_data[0]
	_scene.note_type = _note_data[1]
	_scene.sustain_length = _note_data[2]
	
	if len(_note_data) >= 4:
		_scene.note_value = _note_data[3]
	
	_scene.must_hit = _must_hit
	_scene.scroll_speed = cur_chart.scroll_speed
	
	_scene.is_online = _is_online
	
	_scene.position.y = 2000
	
	_scene.connect("note_hit", self, "note_hit")
	_scene.connect("note_missed", self, "note_missed")
	
	emit_signal("note_created", _scene)
	
	for _button in _strum.get_children():
		if _button.note_type == _scene.note_type:
			_scene.button = _button

			_button.get_node("Notes").add_child(_scene)
			
# Get data from the current section.
func get_section() -> void:
	if len(cur_chart.sections) <= 0:
		return
	
	var _next_section = cur_chart.sections[0]
	
	if (_next_section[0] - Conductor.song_position) <= 0:
		must_hit = _next_section[1]
		
		cur_chart.sections.remove(0)
			
# When any note is hit.
func note_hit(_note : Node, _timing : float, _online : bool = false) -> void:
	var _character = player_character
	if !_note.must_hit:
		_character = enemy_character
	
	var is_player = _note.button.get_parent().is_player
	_note.button.get_parent().character = _character
	
	emit_signal("note_hit_any", _note, _timing)
	if is_player && !_note.is_online:
		emit_signal("note_hit", _note, _timing)
		
	var _note_char = _note.button.get_parent().character
	
	if _note_char != null and _note.do_anim:
		var _anim_array = _note.button.get_parent().ANIM_ARRAY
		
		_note_char.play(_anim_array[_note.note_type], 1)
		
		if is_player:
			_note_char.last_action = _note.button.get_parent().BUTTON_ACTIONS[_note.note_type]
	
	if is_player:
		var _rating = get_rating(_note.hit_timings, _timing)
		
		var _online_data = {}
		
		var _create_rating = true
		if !_note.do_hit:
			_create_rating = false
		
		if _note.is_online:
			if player_data.has(opponent):
				_online_data = player_data[opponent]
		
		if _note.pressed:
			return
		
		if Settings.note_splashes:
			if _rating == _note.hit_timings.keys().back():
				var _splash = NOTE_SPLASH.instance()
				
				_splash.note = _note.note_type
				_note.button.add_child(_splash)
		
		if _create_rating:
			var _combo = combo
			if _note.is_online:
				_combo = _online_data.get("combo", 0)
				
			create_rating(_rating, _combo+1, !_note.must_hit)
		
		if !_note.is_online:
			if _note.do_hit:
				hit_notes += 1
				accuracy_sum +=_note.hit_timings[_rating][2]
				combo += 1
				
				health += _note.health
				score += _note.hit_timings[_rating][1]
				
				timing_sum += _timing
			
			if Settings.hit_sounds:
				hitsound_stream.play()
			
			rpc("online_note_hit", Conductor.song_position, _note.strum_time, is_enemy, _note.note_type)
			send_player_info()
			
			hud.update_info_bar()
		
	Conductor.mute_vocals = false

# When a note is missed because its passed.
func note_missed(_note : Node) -> void:
	emit_signal("note_missed_any", _note)
	if !_note.is_online:
		emit_signal("note_missed", _note)

	if _note.do_miss:
		on_miss(_note.button, true, _note.is_online)

# When a note is missed.
func on_miss(_button : Node, _passed = false, _online = false):
	var _character = _button.get_parent().character
	var is_player = _button.get_parent().is_player
	
	if _online:
		return
		
	if _character != null && _character.use_miss:
		var _anim_array = _button.get_parent().ANIM_ARRAY
		
		_character.play(_anim_array[_button.note_type] + "-miss", 1)
		
		if is_player:
			_character.last_action = ""
		
	if is_player:
		if _passed:
			missed_notes += 1
			accuracy_sum -= 1
			
			Conductor.mute_vocals = true
		else:
			fake_missed_notes += 1
			
		if combo >= 1:
			if stage.gf_character != null:
				stage.gf_character.play("cry", 0.5)
		
		combo = 0
		
		health -= 5.0
		score -= 10
		
		create_rating("miss", 0, is_enemy)
		
		MISS_SOUNDS.shuffle()
		
		miss_stream.stream = MISS_SOUNDS[0]
		miss_stream.play()
		
		hud.shake_bar()
		hud.update_info_bar()
		
		send_player_info()

# Gets the rating from the notes hit timing dictionary.
func get_rating(_hit_timings : Dictionary, _timing : float) -> String:
	var _ratings = _hit_timings.keys()
	var _chosen_rating = _ratings[_ratings.size()-1]
	
	for _rating in _ratings:
		var _max_timing = 0
		if (_ratings.find(_rating) + 1 < _ratings.size()):
			_max_timing = _hit_timings[_ratings[_ratings.find(_rating) + 1]][0]
		
		if (abs(_timing) < _max_timing):
			continue
		else:
			_chosen_rating = _rating
			break
	
	return _chosen_rating
	
func create_rating(_rating, _combo, _left):
	var _rating_parent = stage
	if Settings.hud_ratings:
		_rating_parent = hud
	
	if rating_scene == null || Settings.showcase_mode:
		_rating_parent = null
	
	if _rating_parent != null:
		var _rating_object = rating_scene.instance()
		
		_rating_object.rating = _rating
		_rating_object.combo = _combo
		
		if _rating_parent == stage:
			_rating_object.position = _rating_parent.gf_position + Vector2(160, -400)
		
		if _left:
			if !Settings.hud_ratings:
				_rating_object.position.x -= 260
		
		if _rating_parent == hud:
			_rating_parent.get_node("Ratings").add_child(_rating_object)
		else:
			_rating_parent.add_child(_rating_object)
	
func game_over() -> void:
	var _scene = GAME_OVER_SCENE.instance()
	
	var _offset = player_character.get_node("Sprite").position + Vector2(-70, 0)
	_scene.get_node("Sprite").position = player_character.position + _offset
	_scene.get_node("Camera").position = stage.get_node("Camera").position
	
	_scene.playstate_data = {
		"song_directory": song_directory,
		"song_name": song_name,
		"song_difficulty": song_difficulty,
	}
	
	Main.change_scene_node(_scene)
	
func pause() -> void:
	var _scene = PAUSE_SCENE.instance()
	_scene.play_state = self
	call_deferred("add_child", _scene)
	
# Makes the stream players like the miss stream.
func create_stream_players() -> void:
	miss_stream = AudioStreamPlayer.new()
	miss_stream.bus = "SFX"
	add_child(miss_stream)
	
	hitsound_stream = AudioStreamPlayer.new()
	hitsound_stream.stream = HIT_SOUND
	hitsound_stream.volume_db = Settings.hit_sound_volume
	hitsound_stream.bus = "SFX"
	add_child(hitsound_stream)
	
	hey_stream = AudioStreamPlayer.new()
	hey_stream.stream = HEY_SOUND
	hey_stream.volume_db = 5
	hey_stream.bus = "SFX"
	add_child(hey_stream)
	
# Restart the current playstate.
func restart_playstate() -> void:
	emit_signal("song_restarted")
	
	if stop_automatically:
		var _new_playstate = Main.create_playstate(song_directory, song_name, song_difficulty)
		Main.change_scene_transition(_new_playstate)
	
# Check if the song has ended.
func song_end_check() -> void:
	if Conductor.music_stream.stream == null:
		return
	
	if !started:
		return
	if finished:
		return
	
	if Conductor.song_position >= Conductor.music_stream.stream.get_length() * 1000:
		Conductor.stop_music()
		
		emit_signal("song_ended")
		
		online_finish()
		
func load_scripts():
	if mod_directory != null:
		load_script(mod_directory + "script.gd")
		load_script(song_directory + "script.gd")
		
		load_script(mod_directory + "stages/" + cur_chart.stage + ".gd")
	
	var _characters = [stage.player_character, stage.enemy_character, stage.gf_character]
	for _character in _characters:
		if "character_dir" in _character:
			load_script(_character.character_dir + "script.gd", {"character": _character})
	
func load_script(_dir, _data = {}, allow_resources = true):
	var file = Mods.mod_script(_dir)
	
	if (file is GDScript):
		var node = file.new()
		
		if (node is FNFScript):
			node.script_path = _dir
			
			node.play_state = self
			node.character = _data.get("character")
				
			add_child(node)
			
			print("Loaded script %s." % _dir)
			
			if allow_resources:
				for resource in node._get_resources():
					var _path = "mods/%s/" % song_mod + resource
					script_resources.append(_path.simplify_path())
				for feature in node._get_features():
					var _path = "features/" + feature + ".gd"
					script_resources.append(_path.simplify_path())
			
			return node
		else:
			print("Script %s is not type FNFScript and cannot be loaded." % _dir)
	
	return null

func load_script_features():
	var features = []
	var feature_nodes = {}
	
	for script_node in get_tree().get_nodes_in_group("_scripts"):
		features.append_array(script_node._get_features())
	
	for feature in features:
		var feature_node
		var file_path = "features/" + feature + ".gd"
		
		var file = File.new()
		
		var prefixes = [Mods.mods_folder, Resources.temp_online_folder]
		for prefix in prefixes:
			if file.file_exists(prefix + file_path):
				feature_node = load_script(prefix + file_path, {}, false)
				break
		
		if feature_node:
			feature_nodes[feature] = feature_node
	
	for script_node in get_tree().get_nodes_in_group("_scripts"):
		var script_features = script_node._get_features()
		for feature in feature_nodes:
			if feature in script_features:
				script_node._features[feature] = feature_nodes[feature]
		
func online_ready():
	if !get_tree().is_network_server():
		rpc_id(1, "player_ready")
	else:
		player_ready(1)
		
func online_finish():
	finished = true
	
	if !get_tree().is_network_server():
		rpc_id(1, "player_finished")
	else:
		player_finished(1)
		
func send_player_info():
	var _data = {
		"score": score,
		"misses": missed_notes,
		"hit_notes": hit_notes,
		"accuracy_sum": accuracy_sum,
		"combo": combo,
	}
	
	rpc("get_player_info", _data)
	
func update_stats():
	if is_solo:
		return

	var _wins = Settings.multi_data.get("wins", 0)
	var _losses = Settings.multi_data.get("losses", 0)
	var _accuracy = Settings.multi_data.get("accuracy", 0)
	
	if check_if_won():
		Settings.multi_data.wins = _wins + 1
	else:
		Settings.multi_data.losses = _losses + 1
		
	Settings.multi_data.accuracy = (_accuracy + get_accuracy(hit_notes, accuracy_sum)) / 2
	
# Get the current accuracy.
func get_accuracy(_hit_notes, _accuracy_sum) -> float:
	var _acc = 1
	
	if _hit_notes != 0:
		_acc = float(_accuracy_sum) / float(_hit_notes)
		
	if _accuracy_sum <= 0:
		_acc = 0
	
	return _acc

func check_if_won():
	if is_solo:
		return true
	
	var _opponent_data = player_data.get(opponent, {})
	var _opponent_score = _opponent_data.get("score", 0)

	return _opponent_score < score
	
remote func get_player_info(_data):
	var _id = get_tree().get_rpc_sender_id()
	
	player_data[_id] = _data
	hud.update_multi_info_bar()
	
remote func player_ready(_id = null):
	if _id == null:
		_id = get_tree().get_rpc_sender_id()
	ready_players.append(_id)
	
	check_all_ready()
	
remote func player_finished(_id = null):
	if _id == null:
		_id = get_tree().get_rpc_sender_id()
	
	finished_players.append(_id)
	
	check_all_finished()

func check_all_ready():
	if len(playing_players) <= len(ready_players):
		online_start()
		rpc("online_start")
		
func check_all_finished():
	if len(playing_players) <= len(finished_players):
		online_finished()
		rpc("online_finished")
	
remote func online_start():
	print("All players are ready! Starting the game.")
	hud.hide_waiting()
	
	started = true
	start_song()
	
remote func online_finished():
	print("All players are finished! goobye.")
	var _song_finished = finished
	
	if _song_finished:
		update_stats()
	
	Conductor.stop_music()
	Main.change_scene_transition("res://Scenes/States/Multiplayer/MultiLobby.tscn")
	
remote func online_note_hit(_ms, _strum_time, _is_player, _dir):
	var _id = get_tree().get_rpc_sender_id()
	
	if _id == opponent:
		if !player_hits.has(_id):
			player_hits[_id] = []

		var _opponent_offset = Conductor.song_position - _ms
		if _opponent_offset < 0:
			_opponent_offset = 0

		update_strum_offset(_opponent_offset)

		player_hits[_id].append([_ms, _strum_time, _is_player, _dir])
	else:
		var _anim_array = ["left", "down", "up", "right"]

		var _char = stage.characters_node.get_node_or_null(str(_id))
		if _char != null:
			_char.play(_anim_array[_dir], 1)

func start_hey_anim(_alt_key = false):
	var _my_id = get_tree().get_network_unique_id()
		
	do_hey_anim(is_enemy, _my_id, _alt_key)
	rpc("do_hey_anim", is_enemy, _my_id, _alt_key)
	
	do_hey = false

remote func do_hey_anim(_enemy, _id = null, _alt_key = false):
	if _id == null:
		_id = get_tree().get_rpc_sender_id()
	
	var _character = get_character_from_id(_id)
	_character.taunt(_alt_key)
	
	if _character.do_taunt_sound:
		hey_stream.stream = _character.taunt_sound
		hey_stream.play()

func update_strum_offset(_offset):
	var _strum = enemy_strum
	if is_enemy:
		_strum = player_strum
		
	var _difference = abs(_strum.offset - _offset)
	if _difference > 100:
		print("Updated opponent's offset.\nNew offset: %sms. Difference: %s" % [_offset, _difference])
		_strum.offset = _offset

func finished_loading():
	load_script_features()
	
	emit_signal("loaded")
	online_ready()
		
func _player_disconnected(_id):
	playing_players.erase(_id)
	
	if !started:
		check_all_ready()
		
func _on_beat(_cur_beat):
	if do_hey:
		start_hey_anim()
		
func get_opponent_data():
	var _opponent_data = {}
	if player_data.has(opponent):
		_opponent_data = player_data[opponent]
	
	return _opponent_data

func get_relative_character(_character):
	var _player_character = stage.player_character
	var _enemy_character = stage.enemy_character
	var _gf_character = stage.gf_character

	if _character == CHARACTERS.GF:
		return _gf_character

	if _character == CHARACTERS.PLAYER:
		if is_enemy:
			return _enemy_character
		else:
			return _player_character

	if _character == CHARACTERS.OPPONENT:
		if is_enemy:
			return _player_character
		else:
			return _enemy_character

	return 1
	
func get_character_from_id(_id):
	var _my_id = get_tree().get_network_unique_id()
	
	var _character_main = null
	if _id == _my_id:
		_character_main = CHARACTERS.PLAYER
	if _id == opponent:
		_character_main = CHARACTERS.OPPONENT
	
	if _character_main != null:
		return get_relative_character(_character_main)
	else:
		return stage.fake_characters.get(_id, 1)

# GETTERS AND SETTERS
func get_player_strum():
	if hud == null: return null
	return hud.get_node_or_null(hud.player_strum)
	
func get_enemy_strum():
	if hud == null: return null
	return hud.get_node_or_null(hud.enemy_strum)
	
func get_player_character():
	if stage == null: return null
	return stage.player_character
	
func get_enemy_character():
	if stage == null: return null
	return stage.enemy_character
