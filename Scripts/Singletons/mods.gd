extends Node

var mods_folder = OS.get_executable_path().get_base_dir() + "/mods/"
var songs_folder setget ,get_songs_folder
var characters_folder setget ,get_characters_folder

func _ready():
	if !(OS.has_feature("standalone")):
		mods_folder = "res://.mods/"
	
	var dir = Directory.new()
	if (!dir.dir_exists(mods_folder)):
		dir.make_dir(mods_folder)

# loading
func mod_ogg(_dir):
	if (check_if_native(_dir)):
		return load(_dir)
	else:
		var _song_file = File.new();
		
		var _open_error = _song_file.open(_dir, File.READ);
		
		var d = AudioStreamOGGVorbis.new();
		if _open_error == OK:
			var b = _song_file.get_buffer(_song_file.get_len())
			d.data = b
		
		return d

func mod_image(_dir):
	if (check_if_native(_dir)):
		return load(_dir)
	else:
		var image = Image.new();
		image.load(_dir)
		
		var texture = ImageTexture.new()
		texture.create_from_image(image)

		return texture

func mod_script(_dir):
	var scriptFile = File.new();
	if (scriptFile.file_exists(_dir)):
		return load(_dir)
	else:
		return 1

# other
func check_if_native(dir):
	return (dir.begins_with("res://") && !dir.begins_with(mods_folder))
	
func scan_directory(_directory):
	var _structure : Dictionary
	
	var _dir = Directory.new()
	_dir.open(_directory)
	
	_dir.list_dir_begin(true)
	while true:
		var file = _dir.get_next()
		if file == "":
			break
		else:
			if _dir.current_is_dir():
				var _next_dir = _directory + file + "/"
				_structure[file] = scan_directory(_next_dir)
			else:
				_structure[file] = ""
	
	return _structure

# get and set
func get_songs_folder():
	return mods_folder + "/mods/"

func get_characters_folder():
	return mods_folder + "/characters/"
