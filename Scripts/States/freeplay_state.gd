extends Node2D

# The freeplay choice node.
const FREEPLAY_CHOICE = preload("res://Scenes/States/Freeplay/FreeplayChoice.tscn")

# All the songs in freeplay.
# ex. ("tutorial": [song dir])
var freeplay_songs : Dictionary

# The current selected difficulty.
var selected_dif = Chart.Difficulties.HARD

# The currently selected songs data.
var selected_song_data : SongData
# The currently selected songs instrumental.
var selected_song_inst : AudioStreamOGGVorbis
# The info that is displayed for the current song.
var info_string : String

# The node used for the thread stuff.
var freeplay_thread : Node

# Godot ready function.
func _ready():
	# Get all the songs.
	freeplay_songs = get_freeplay_songs()
	
	# Add them to the choice menu and update the menu.
	create_choices()
	
	# Create the thread node.
	freeplay_thread = load("res://Scripts/States/Freeplay/freeplay_thread.gd").new()
	add_child(freeplay_thread)
	
	freeplay_thread.ready_thread()
	var _error = freeplay_thread.connect("got_song_data", self, "_got_song_data")
	
	get_song_data()
	
	# Stop the song.
	Conductor.stop_music()

# Godot process function.	
func _process(delta):
	$Difficulty.frame = selected_dif
	
	if $Difficulty.offset.y < 0:
		$Difficulty.offset.y += delta * 300
	else:
		$Difficulty.offset.y = 0
	
	$InfoLabel.text = info_string
	
# Godot input function.
func _input(event):
	if event.is_pressed():
		var _move = int(event.is_action("right")) - int(event.is_action("left"))
		
		if _move != 0:
			selected_dif += _move
			$Difficulty.offset.y = -20
			
		if selected_dif < 0:
			selected_dif = len(Chart.Difficulties) - 1
		if selected_dif > len(Chart.Difficulties) - 1:
			selected_dif = 0
			
		if _move != 0:
			get_song_data()
			
		if event.is_action_pressed("cancel"):
			$CancelStream.play()
			Main.change_scene_transition(Main.MAIN_MENU_SCENE)

# Get all songs within a folder.
func get_freeplay_songs(_directory = "res://Assets/Songs/") -> Dictionary:
	var _temp_freeplay_data : Dictionary
	
	var _dir = Directory.new()
	_dir.open(_directory)
	
	_dir.list_dir_begin(true)
	while true:
		var file = _dir.get_next()
		if file == "":
			break
		else:
			_temp_freeplay_data[file] = [_directory + file + "/"]
	
	return _temp_freeplay_data

# Get a songs data from the thread.
# Defaults to the currently selected song.
func get_song_data(index = $ChoiceMenu.selected):
	var _song = freeplay_songs.keys()[index]
	var _song_data = freeplay_songs[_song]
	
	var _song_dir = _song_data[0]
	
	freeplay_thread.get_song_data(_song_dir, _song + Chart.dif_exts[selected_dif] + ".json")

	info_string = "Loading..."

# Update the info string.
func update_info_string():
	info_string = ""
	
	info_string += "File Name: " + str(selected_song_data.file_name)
	info_string += "\n" + "Song Directory: " + str(selected_song_data.song_dir)
	
	info_string += "\n\n" + "Song Name: " + str(selected_song_data.song_name)
	info_string += "\n" + "BPM: " + str(selected_song_data.bpm)
	info_string += "\n" + "Voices: " + str(selected_song_data.use_voices)
	
	info_string += "\n\n" + "BF: " + str(selected_song_data.bf)
	info_string += "\n" + "Enemy: " + str(selected_song_data.enemy)
	info_string += "\n" + "GF: " + str(selected_song_data.gf)
	
	info_string += "\n\n" + "Scroll Speed: " + str(selected_song_data.scroll_speed)

# Create the objects inside the choice menu.
func create_choices() -> void:
	var _alphabet_node = $ChoiceMenu.alphabet_node
	$ChoiceMenu.choices = freeplay_songs.keys()
	
	for _existing_choice in _alphabet_node.get_children():
		_existing_choice.queue_free()
	
	var _i = 0
	for _choice in $ChoiceMenu.choices:
		var _scene = FREEPLAY_CHOICE.instance()
		
		var _song_data = freeplay_songs[_choice]
		var _song_dir = _song_data[0]
		
		var _chart = SongData.new()
		_chart.load_chart(_song_dir, _choice + ".json", true)
		
		_scene.text = _choice
		if Resources.characters.has(_chart.enemy):
			_scene.icon = _chart.enemy
		_scene.name = str(_i)
		_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		_alphabet_node.add_child(_scene)
		
		_i += 1


# Play the song.
func _on_ChoiceMenu_option_selected(index):
	var _song = freeplay_songs.keys()[index]
	
	var _song_directory = "res://Assets/Songs/" + _song + "/"
	var _song_name = _song
	
	var _play_state = Main.create_playstate(_song_directory, _song_name, selected_dif)
	
	if _play_state is PlayState:
		Main.change_scene_transition(_play_state)
	else:
		match _play_state:
			Main.PlayStateCreateError.CANNOT_LOAD_CHART:
				print("Could not load the chart. (", _song_name ,")\nMake sure the json file is named correctly.")

# Once a option is changed load that song.
# Not used yet.
func _on_ChoiceMenu_option_changed(index):
	get_song_data(index)

# Once the song data is got from the thread.
func _got_song_data(_song_data, _inst):
	freeplay_thread.mutex.lock()
	
	selected_song_data = _song_data
	
	if _song_data is SongData:
		selected_song_inst = _inst
		
		if selected_song_inst != null && selected_song_data != null:
			if selected_song_data.bpm != null:
				Conductor.play_song(selected_song_inst, null, selected_song_data.bpm, 2)
		
		update_info_string()
	else:
		var _song = freeplay_songs.keys()[$ChoiceMenu.selected]
		Conductor.stop_music()
		
		info_string = "Failed to load the chart.\nDoes " + _song + Chart.dif_exts[selected_dif] + ".json exist?"
	
	freeplay_thread.mutex.unlock()
