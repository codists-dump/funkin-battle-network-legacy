extends WindowDialog

signal picked_song(_song_data)

signal online_mods_downloaded()

const MOD_MESSAGE = "Getting mods, please wait..."

var freeplay_data = {}

var selected

var selected_mod

var search_text

var diff_strings = ["Easy", "Normal", "Hard"]

var use_online = false

var getting_online_songs = false

var http = HTTPRequest.new()

var mod_buttons = {}
var song_buttons = {}

var total_mods = 0.0
var finished_mods = 0.0
var downloading_mods = []

var random = RandomNumberGenerator.new()

onready var mod_container = $container/option_container/mod_container/container
onready var song_container = $container/option_container/song_container/container

onready var refresh_button = $container/top_container/refresh_button

func _ready():
	random.randomize()
	
	get_all_freeplay_data()
	
	popup_centered()
	
	$container/top_container/search_bar.grab_focus()
	
	http.timeout = 30
	add_child(http)
	
	$container/top_container/lolserver.text = Resources.online_repo_address
	
	var _connect_closed = connect("modal_closed", self, "_closed")
	
func _process(_delta):
	$container/top_container/lolserver.visible = use_online
	$container/song_tabs.tabs_visible = not getting_online_songs
	
func _closed():
	queue_free()
	
func get_all_freeplay_data(_force = false):
	if !use_online:
		$InfoLabel.visible = false
	
		freeplay_data = get_freeplay_data()
		var _mod_freeplay_data = get_freeplay_data(Mods.songs_folder, true)
		
		Main.merge_dictionarys(freeplay_data, _mod_freeplay_data)
		
		setup_mods()
		setup_songs()
	else:
		$InfoLabel.visible = true
		
		clear_container(mod_container)
		clear_container(song_container)
	
		get_online_freeplay_data(_force)
	
func get_freeplay_data(_directory = "res://Assets/Songs/", _is_mod = false):
	var _temp_freeplay_data : Dictionary
	
	var _dir = Directory.new()
	
	if _dir.dir_exists(_directory):
		var _error_dir = _dir.open(_directory)
		if _error_dir != OK:
			return
		
		_dir.list_dir_begin(true)
		while true:
			var _mod = _dir.get_next()
			if _mod == "":
				break
			else:
				if !_dir.current_is_dir():
					continue
					
				if _mod.begins_with("."):
					continue
				
				var _mod_dir = _directory + _mod + "/songs/"
				
				var _songs_dir = Directory.new()
				var _error_songs = _songs_dir.open(_mod_dir)
				if _error_songs != OK:
					continue
				
				var _temp_songs = []
				
				_songs_dir.list_dir_begin(true)
				while true:
					var _song = _songs_dir.get_next()
					if _song == "":
						break
					else:
						if !_songs_dir.current_is_dir():
							continue
							
						if _song.begins_with("."):
							continue
						
						_temp_songs.append(_song)
				
				_temp_freeplay_data[_mod] = {
					"songs": _temp_songs,
					"dir": _mod_dir,
				}
				
				if len(_temp_freeplay_data[_mod]["songs"]) == 0:
					var _erased = _temp_freeplay_data.erase(_mod)
	
	return _temp_freeplay_data

func get_online_freeplay_data(_force = false):
	freeplay_data = {}
	
	if Resources.online_freeplay_data.empty() or _force:
		Resources.online_freeplay_data = {}
		
		set_label_text(MOD_MESSAGE + "\nGetting mod list...")
		
		getting_online_songs = true
		
		var _mods_path = Resources.get_github_content_path(
			Resources.online_repo_address, 
			"mods"
		)
		
		var _error_mods = Resources.github_http_request(http, _mods_path)
		if _error_mods != OK:
			set_error_label_text(_error_mods)
			getting_online_songs = false
			return
		
		var _mods_result = yield(http, "request_completed")
		if _mods_result[1] != 200:
			print(_mods_result[3])
			
			set_error_label_text(_mods_result[1])
			getting_online_songs = false
			return
			
		var _mods = parse_json(_mods_result[3].get_string_from_utf8())
		total_mods = len(_mods)
		for _mod in _mods:
			var _mod_name = _mod.get("name")
			
			downloading_mods.append(_mod_name)
			get_online_mod_freeplay_data(_mod, _mods_path)
		
		yield(self, "online_mods_downloaded")
	
	freeplay_data = Resources.online_freeplay_data
	
	getting_online_songs = false
	
	$InfoLabel.visible = false
	
	setup_mods()
	setup_songs()
	
func get_online_mod_freeplay_data(_mod, _mods_path):
	var _http = HTTPRequest.new()
	add_child(_http)
	
	var _mod_name = _mod.get("name")
	
	var _songs_path = _mods_path + "/%s/songs" % _mod_name.replace(" ", "%20")

	var _error_songs = Resources.github_http_request(_http, _songs_path)
	if _error_songs != OK:
		print(_mod_name + " ERROR / " + _error_songs)

	var _songs_result = yield(_http, "request_completed")
	if _songs_result[1] != 200:
		print(_mod_name + " ERROR / " + _songs_result[1])
	
	_http.queue_free()

	var _songs_data = parse_json(_songs_result[3].get_string_from_utf8())
	var _temp_songs = {}
	for _song in _songs_data:
		var _song_name = _song.get("name")
		
		if _song.get("type") != "dir":
			continue
		
		var _temp_song = {}
		
		var _diffs = [0, 1, 2]
		_temp_song["diffs"] = _diffs
		
		_temp_songs[_song_name] = _temp_song

	Resources.online_freeplay_data[_mod_name] = {
		"songs": _temp_songs,
	}
	
	finished_mods += 1
	var _mod_percent = (finished_mods / total_mods) * 100
	set_label_text(MOD_MESSAGE + "\nGetting songs... (%s)\n%d%%" % [_mod_name, _mod_percent])
	
	downloading_mods.erase(_mod_name)
	if downloading_mods.empty():
		emit_signal("online_mods_downloaded")

func create_mods():
	var _all_button = create_all_button()
	
	if selected_mod == null:
		_all_button.pressed = true
	
	mod_container.add_child(_all_button)
	mod_container.add_child(HSeparator.new())
	
	for _mod in freeplay_data:
		var _songs = freeplay_data.get(_mod, {}).get("songs", [])
		var _missing_songs = 0
		for _song in _songs:
			if !search_check(_song):
				_missing_songs += 1
				
		if _missing_songs == len(_songs):
			continue
		
		var _button = Button.new()
		_button.text = _mod
		_button.toggle_mode = true
		_button.clip_text = true
		
		mod_buttons[_mod] = _button
		
		if selected_mod == _mod:
			_button.pressed = true

		_button.connect("pressed", self, "chose_mod", [_mod, _button])
		
		mod_container.add_child(_button)

func create_all_button():
	var _button = Button.new()
	_button.text = "ALL"
	_button.toggle_mode = true
	_button.clip_text = true
	
	_button.connect("pressed", self, "chose_all_mods", [_button])
	
	return _button

func create_songs(_mod = selected_mod):
	if _mod == null:
		return
	
	if !freeplay_data.has(_mod):
		return
	
	for _song in freeplay_data[_mod]["songs"]:
		if !search_check(_song):
			continue
		
		var _button = Button.new()
		
		var _song_name = _song
		_song_name = _song_name.replace("-", " ")
		_song_name = _song_name.capitalize()
		
		_button.text = _song_name
		_button.toggle_mode = true
		_button.clip_text = true
		
		_button.hint_tooltip = "%s\n%s" % [_song_name, _mod]
		
		if selected != null:
			if selected.get("mod", null) == _mod:
				if selected.get("song", null) == _song:
					_button.pressed = true
		
		var _song_data = {
			"mod": _mod,
			"song": _song,
			"is_online": use_online,
			"online_repo": Resources.online_repo_address,
		}
		_button.connect("pressed", self, "chose_song", [_song_data, _button])
		
		song_container.add_child(_button)

func clear_container(_container):
	for _child in _container.get_children():
		_child.queue_free()

func get_song_diffs(_mod, _song):
	var _diffs = []
	
	if freeplay_data[_mod].get("songs", []) is Dictionary:
		var _data = freeplay_data[_mod]["songs"].get(_song, null)
		
		if _data != null:
			_diffs = _data.get("diffs", [])
	else:
		var _mod_dir = freeplay_data[_mod].get("dir", null)
		
		if _mod_dir == null:
			return [0, 1, 2]
		
		var _file_dir = _mod_dir + _song + "/" + _song
		
		for _diff in len(Chart.Difficulties):
			var _ext = Chart.dif_exts[_diff]
			var _test_file = _file_dir + _ext + ".json"
			
			var _file = File.new()
			if _file.file_exists(_test_file):
				_diffs.append(_diff)
	
	return _diffs

func update_selected():
	var _mod = selected.get("mod", "")
	var _song = selected.get("song", "")
	var _diffs = get_song_diffs(_mod, _song)
	
	var _selected_label = $container/bot_container/selected_container/selected_label
	var _diff_option = $container/bot_container/selected_container/diff_option
	
	$container/bot_container/select_button.text = "Pick"
	
	_selected_label.text = _song
	
	_diff_option.clear()
	
	for _diff in _diffs:
		var _diff_str = diff_strings[_diff]
		_diff_option.add_item(_diff_str)
	
	_diff_option.select(_diff_option.get_item_count()-1)
		
func chose_mod(_mod, _button):
	selected_mod = _mod
	
	set_selected_button(_button)
	setup_songs()

func chose_all_mods(_button=null):
	selected_mod = null
	
	if _button != null:
		set_selected_button(_button)
	
	setup_songs()

func create_all_songs():
	for _mod in freeplay_data:
		create_songs(_mod)
		
func setup_songs():
	clear_container(song_container)
	
	if selected_mod == null:
		create_all_songs()
	else:
		create_songs()

func setup_mods():
	clear_container(mod_container)
	
	create_mods()

func chose_song(_song_data, _button):
	selected = _song_data
	
	update_selected()
	
	update_diff()
	
	set_selected_button(_button)

func set_selected_button(_button):
	for _child in _button.get_parent().get_children():
		if _child is Button:
			_child.pressed = false
		
	_button.pressed = true

func update_diff():
	var _diff_option = $container/bot_container/selected_container/diff_option
	var _diff_str = _diff_option.get_item_text(_diff_option.selected)
	
	selected["diff"] = diff_strings.find(_diff_str)

func search_check(_song):
	if search_text == null:
		return true
	
	var _song_name = _song.to_lower()
	_song_name = _song_name.replace("-", " ")
	
	if _song_name.count(search_text.to_lower()) > 0:
		return true
	
	return false
	
func set_label_text(_text=""):
	var _label = $InfoLabel
	
	if _label.visible == false:
		_label.visible = true
	
	_label.text = _text

func set_error_label_text(_error=OK):
	var _message = ""
	
	match _error:
		403:
			_message = "\nGitHub API rate limit exceeded."
	
	set_label_text("ERROR %s%s" % [_error, _message])

func _on_select_button_pressed():
	emit_signal("picked_song", selected)
	queue_free()

func _on_diff_option_item_selected(_index):
	update_diff()

func _on_search_bar_text_changed(new_text):
	search_text = new_text
	if search_text == "":
		search_text = null
		
	if getting_online_songs:
		return
	
	setup_mods()
	setup_songs()

func _on_TabContainer_tab_changed(tab):
	use_online = tab == 1
	
	selected_mod = null
	
	get_all_freeplay_data()

func _on_lolserver_text_changed(new_text):
	Resources.online_repo_address = new_text


func _on_random_button_pressed():
	if len(freeplay_data) == 0:
		return
	
	var _random_mod = random.randi() % len(freeplay_data)
	var _mod = freeplay_data.keys()[_random_mod]
	var _button = mod_buttons[_mod]
	
	chose_mod(_mod, _button)
	_button.grab_focus()
	
	var _mod_songs = freeplay_data[_mod]["songs"]
	if _mod_songs is Dictionary:
		_mod_songs = _mod_songs.keys()
	
	var _random_song = random.randi() % len(_mod_songs)
	var _song = _mod_songs[_random_song]
	
	var _song_name = _song
	_song_name = _song_name.replace("-", " ")
	_song_name = _song_name.capitalize()
	
	for _song_button in song_container.get_children():
		if _song_button.text == _song_name:
			var _data = {
				"mod": _mod,
				"song": _song,
				"is_online": use_online,
				"online_repo": Resources.online_repo_address,
			}
			
			chose_song(_data, _song_button)


func _on_refresh_button_pressed():
	get_all_freeplay_data(true)
