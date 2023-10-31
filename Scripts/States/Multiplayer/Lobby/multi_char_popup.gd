extends WindowDialog

signal picked_character(_character)

var characters : Dictionary

var selected

var search_text

var use_online = false

var getting_online_characters = false

var getting_online_icon = false

var http = HTTPRequest.new()

onready var char_container = $container/main_container/character_container/container

onready var icon_preview = $container/main_container/preview_container/icon_preview
onready var loading_icon = $container/main_container/preview_container/icon_preview/loading_icon

func _ready():
	add_child(http)
	
	get_all_characters()
	setup_characters()
	
	popup_centered()
	
	var _connect_closed = connect("modal_closed", self, "_closed")

func _process(_delta):
	$container/song_tabs.tabs_visible = not getting_online_characters
	
	loading_icon.visible = getting_online_icon
	if getting_online_icon:
		loading_icon.rect_rotation += 1000 * _delta

func _closed():
	queue_free()

func get_all_characters(_force = false):
	if !use_online:
		characters = get_characters()
		var _mod_characters = get_characters(Mods.characters_folder)
		
		Main.merge_dictionarys(characters, _mod_characters)
	else:
		get_online_characters(_force)
	
func get_characters(_directory = "res://Assets/Characters/"):
	var _temp_characters = {}

	var _dir = Directory.new()
	
	if _dir.dir_exists(_directory):
		_dir.open(_directory)
		
		_dir.list_dir_begin(true)
		while true:
			var _character = _dir.get_next()
			if _character == "":
				break
			else:
				var _char_dir = _directory + "/" + _character + "/"
				
				_temp_characters[_character] = _char_dir
	
	return _temp_characters

func get_online_characters(_force = false):
	var _temp_characters = {}
	
	if Resources.online_character_data.empty() or _force:
		var _loading_text = "Getting characters, please wait..."
		set_label_text(_loading_text)
		
		getting_online_characters = true
		
		var _character_path = Resources.get_github_content_path(
			Resources.online_repo_address, 
			"characters"
		)
		
		http.cancel_request()
		var _error_characters = http.request(_character_path)
		if _error_characters != OK:
			set_error_text(_error_characters)
			getting_online_characters = false
			return
		
		var _characters_result = yield(http, "request_completed")
		if _characters_result[1] != 200:
			set_error_text(_characters_result[1])
			getting_online_characters = false
			return
		
		var _characters = parse_json(_characters_result[3].get_string_from_utf8())
		for _character in _characters:
			var _char_name = _character.get("name", null)
			if _char_name == null:
				continue
			
			_temp_characters[_char_name] = null
		
		Resources.online_character_data = _temp_characters

	getting_online_characters = false
	
	set_label_text("")
	characters = Resources.online_character_data
	setup_characters()

func create_characters():
	for _char in characters:
		if !search_check(_char):
			continue
		
		var _dir = characters[_char]
		
		var _button = Button.new()
		
		var _text = _char.replace("-", " ")
		_text = _text.capitalize()
		_button.text = _text
		
		_button.toggle_mode = true
		_button.clip_text = true
		
		if selected != null:
			if _dir == selected.get("directory", ""):
				if _char == selected.get("character", ""):
					_button.pressed = true

		_button.connect("pressed", self, "chose_character", [_char, _dir, _button])
		
		char_container.add_child(_button)

func setup_characters():
	for _child in char_container.get_children():
		_child.queue_free()
		
	create_characters()
	update_preview()

func chose_character(_character, _directory, _button):
	selected = {
		"character": _character,
		"directory": _directory,
		"is_online": use_online,
	}
	
	if use_online:
		selected["online_repo"] = Resources.online_repo_address
	
	print(selected)
	
	update_preview()
	set_selected_button(_button)
	
func set_selected_button(_button):
	for _child in _button.get_parent().get_children():
		if _child is Button:
			_child.pressed = false
		
	_button.pressed = true
	
func update_preview():
	if selected == null:
		icon_preview.texture = null
		return
	
	if !use_online:
		var _icon_path = selected.directory + "icon-" + selected.character + ".png"
		icon_preview.texture = Mods.mod_image(_icon_path)
	else:
		var _character_path = Resources.get_github_raw_content_path(
			selected.online_repo, 
			"characters/%s/" % selected.character
		)
		
		getting_online_icon = true
		icon_preview.texture = null
		
		var _icon_path = _character_path + "icon-%s.png" % selected.character
		
		http.cancel_request()
		var _error = http.request(_icon_path)
		if _error != OK:
			getting_online_icon = false
			return
		
		var _icon_result = yield(http, "request_completed")
		if _icon_result[1] != 200:
			getting_online_icon = false
			return
		
		var _image = Image.new()
		_image.load_png_from_buffer(_icon_result[3])
		
		var _texture = ImageTexture.new()
		_texture.create_from_image(_image)
		
		icon_preview.texture = _texture
		
		getting_online_icon = false
	
func search_check(_name):
	if search_text == null:
		return true
	
	if _name.count(search_text.to_lower()) > 0:
		return true
	
	return false

func set_label_text(_text):
	$info_text.text = _text

func set_error_text(_error):
	var _message = ""
	set_label_text("ERROR %s%s" % [_error, _message])

func _on_select_button_pressed():
	if selected == null:
		selected = {}
	
	emit_signal("picked_character", selected)
	queue_free()

func _on_search_bar_text_changed(new_text):
	search_text = new_text
	if search_text == "":
		search_text = null
	
	setup_characters()

func _on_song_tabs_tab_changed(tab):
	use_online = tab == 1
	
	selected = null
	update_preview()
	
	if use_online:
		for _child in char_container.get_children():
			_child.queue_free()
	
	get_all_characters()
	
	if not use_online:
		setup_characters()


func _on_refresh_button_pressed():
	selected = null
	update_preview()
	
	if use_online:
		for _child in char_container.get_children():
			_child.queue_free()
	
	get_all_characters(true)
	
	if not use_online:
		setup_characters()
