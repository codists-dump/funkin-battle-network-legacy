extends Node

# resources
var stages = {
	"stage": "res://Scenes/Stages/Stage.tscn"
}

var online_mod_address = "" # deprecated
var online_repo_address = "ImCod2st/fnf-godot-online-mods"
var online_repo_token = ""

var online_freeplay_data = {}
var online_character_data = {}

var temp_online_folder = "user://temp-online/"

func load_character(_character, _directory):
	var _char = PsychCharacter.new()
	_char.character_dir = _directory
	_char.character_file = _character
	
	return _char
	
func get_character_data(_character):
	var _char_data = [
		"bf",
		"res://Assets/Characters/bf/"
	]
	
	var _dir = Resources.get_resource_path("res://Assets/Characters/", Mods.characters_folder, _character)
	if _dir != null:
		_char_data = [
			_character,
			_dir
		]
	
	return _char_data

func get_resource_path(_path1, _path2, _value):
	var _dir = Directory.new()
	
	var _directory = _path2 + _value + "/"
	if !_dir.dir_exists(_directory):
		_directory = _path1 + _value + "/"
	
	if !_dir.dir_exists(_directory):
		return null
	
	return _directory

func get_github_repo_path(_repo):
	return "https://api.github.com/repos/%s" % _repo

func get_github_content_path(_repo, _path):
	return get_github_repo_path(_repo) + "/contents/%s" % _path

func get_github_raw_content_path(_repo, _path):
	return "https://raw.githubusercontent.com/%s/main/%s" % [_repo, _path]

func github_http_request(_http, _url):
	return _http.request(
		_url,
		["Authorization: Bearer %s" % Resources.online_repo_token]
	)

func get_parent_directory(_path):
	_path = _path.simplify_path()
	
	var _split_path = _path.rsplit("/", true, 1)
	return _split_path[0]

func iterate_in_directory_all(_path):
	var _result = {}
	
	var _dirs = [_path]
	while len(_dirs) > 0:
		var _cur_dir = _dirs.pop_front()
		var _dir_result = iterate_in_directory(_cur_dir)
		
		for _file in _dir_result.keys():
			var _is_dir = _dir_result[_file]
			
			if _is_dir:
				_dirs.append(_cur_dir + "/" + _file)
				
		_result[_cur_dir] = _dir_result
		
	return _result
	
func iterate_in_directory(_path):
	var _result = {}
	var _dir = Directory.new()
	
	if _dir.open(_path) == OK:
		_dir.list_dir_begin(true)
		var _file_name = _dir.get_next()
		
		while _file_name != "":
			if _dir.current_is_dir():
				_result[_file_name] = true
			else:
				_result[_file_name] = false
		
			_file_name = _dir.get_next()
	
	return _result
