extends Node

const TRANSITION_SCREEN = preload("res://Scenes/Other/TransitionScene.tscn")

const MAIN_MENU_SCENE = preload("res://Scenes/States/MainMenuState.tscn")

const DEBUG_HUD_SCENE = preload("res://Scenes/Other/DebugHUD.tscn")

const VOLUME_HUD_SCENE = preload("res://Scenes/Other/VolumeHUD.tscn")

enum PlayStateCreateError {
	CANNOT_LOAD_CHART
}

onready var debug_scene = DEBUG_HUD_SCENE.instance()
onready var volume_scene = VOLUME_HUD_SCENE.instance()

# The scene to change to after a transition.
var next_scene

var cur_volume = 5

# Godot ready function.
func _ready():
	get_tree().root.call_deferred("add_child", debug_scene)
	get_tree().root.call_deferred("add_child", volume_scene)

	change_volume(0)
	
	load_env()
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_ENTER:
					if event.alt:
						Settings.full_screen = !Settings.full_screen
				
				KEY_MINUS:
					change_volume(-1)
				KEY_EQUAL:
					change_volume(1)
	
func change_volume(_move):
	cur_volume = clamp(cur_volume + _move, 0, 10)
	
	var _multi = 5
	var _volume = (cur_volume * _multi) - (10 * _multi)
	
	var _index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(_index, _volume)
	AudioServer.set_bus_mute(_index, cur_volume == 0)
	
	if _move != 0:
		volume_scene.volume_updated()

# Change the scene with a transition.
func change_scene_transition(_node):
	var transition_scene = TRANSITION_SCREEN.instance()
	transition_scene.connect("transtioned", self, "transition_finished")
	
	next_scene = _node
	
	get_tree().get_root().add_child(transition_scene)

# Change the scene after the transition is finished.
func transition_finished():
	if next_scene != null:
		change_scene_node(next_scene)

# Change a scene to a node.
func change_scene_node(_node):
	if _node is PackedScene:
		_node = _node.instance()
	if _node is String:
		_node = load(_node).instance()
	
	if !_node.get_parent():
		get_tree().get_root().add_child(_node)
		get_tree().current_scene.queue_free()
		
		get_tree().set_current_scene(_node)

# Create a new playstate.
func create_playstate(
	_song_dir : String,
	_song_name : String,
	_song_dif : int = Chart.Difficulties.NORMAL
):
	var _play_state = PlayState.new()
	
	# The name of the file.
	var _file_name = _song_name
	
	# Check if the file exists.
	var _file = File.new()
	
	# Check for difficulties.
	# If the chosen dif already exists just use that.
	# If not loop through all possible dif extensions and get whatever one exists.
	var _found_dif = false
	
	if _file.file_exists(_song_dir + _file_name + Chart.dif_exts[_song_dif] + ".json"):
		_file_name += Chart.dif_exts[_song_dif]
		_found_dif = true
	else:
		for _dif in len(Chart.Difficulties):
			var _dif_ext = Chart.dif_exts[_dif]
			if _file.file_exists(_song_dir + _file_name + _dif_ext + ".json"):
				_file_name += _dif_ext
				_song_dif = _dif
				_found_dif = true
				break
	
	# Something went wrong wtih finding the file.
	if _found_dif == false:
		return PlayStateCreateError.CANNOT_LOAD_CHART
	
	# Add the json extension.
	_file_name += ".json"
	
	# Load the chart.
	var _chart = SongData.new()
	_chart.load_chart(_song_dir, _file_name)

	# Make sure the characters are valid.
	if Resources.characters.has(_chart.bf):
		_play_state.player_name = _chart.bf
	
	if Resources.characters.has(_chart.enemy):
		_play_state.enemy_name = _chart.enemy
	
	if Resources.characters.has(_chart.gf):
		_play_state.gf_name = _chart.gf
	
	# Set stuff in the play state.
	_play_state.song_directory = _song_dir
	_play_state.song_name = _song_name
	_play_state.song_difficulty = _song_dif 
	
	_play_state.cur_chart = _chart
	
	return _play_state

func print_error(_error):
	print("ERROR %s" % _error)

func create_popup(_text, _title = "Alert!", _type = AcceptDialog):
	var _popup = _type.new()
	_popup.dialog_text = _text
	_popup.window_title = _title
	
	get_tree().current_scene.add_child(_popup)
	_popup.popup_centered()

func merge_dictionarys(target, patch):
	for key in patch:
		target[key] = patch[key]

func load_env():
	var config = ConfigFile.new()
	
	var err = config.load("res://env.ini")
	if err != OK:
		print("[env.ini] No env.ini file exists.")
		return
	
	print("[env.ini] Found env.ini, loading values.")
	
	var repo_token = config.get_value("AUTH", "GITHUB_TOKEN")
	if repo_token != null:
		Resources.online_repo_token = repo_token
		print("[env.ini] Loaded GITHUB_TOKEN.")
