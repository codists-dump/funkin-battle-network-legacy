extends Node2D

var dict = Settings.multi_data

var getting_online_icon = false

var http = HTTPRequest.new()

func _ready():
	add_child(http)
	update_character()

func _process(_delta):
	# name
	$NameText.text = dict.get("name", "Boyfriend")
	
	# INFO TEXT
	var _info = ""
	
	# wins & losses
	var _wins = dict.get("wins", 0)
	var _losses = dict.get("losses", 0)
	var _total_games = _wins + _losses
	
	var _win_ratio = "N/A"
	if _total_games != 0:
		_win_ratio = "%.2f" % ((float(_wins) / float(_total_games)) * 100)
	
	_info += "Wins / Losses: %s / %s" % [_wins, _losses]
	
	_info += "\nWin Ratio: %s" % [_win_ratio] + "%"
	_info += " (%s:%s)" % [_wins, _total_games]
	
	# game stats
	var _accuracy = dict.get("accuracy", 0)
	
	_info += "\n\nAccuracy: " + "%.2f" % (_accuracy * 100) + "%"
	
	# songs
	var _song_data = dict.get("song", {})
	_info += "\n\nFavorite Song:  %s" % [_song_data.get("song", "N/A").replace("-", " ").capitalize()]
	
	# tahda
	$InfoText.text = _info
	
	$IconSprite/LoadingSprite.visible = getting_online_icon
	if getting_online_icon:
		$IconSprite/LoadingSprite.rotation_degrees += 1000 * _delta

func update_character():
	var _char = dict.get("character", {"character": "bf"})
	
	var _icon
	if not _char.get("is_online", false):
		var _char_path = Resources.get_character_data(_char.character)
		_icon = Mods.mod_image(_char_path[1] + "/icon-%s.png" % _char_path[0])
	else:
		$IconSprite.texture = null
		
		getting_online_icon = true
		
		var _icon_path = Resources.get_github_raw_content_path(
			_char.online_repo, 
			"characters/%s/icon-%s.png" % [_char.character, _char.character]
		)
		
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
		
		_icon = ImageTexture.new()
		_icon.create_from_image(_image)
		
		getting_online_icon = false
	
	$IconSprite.texture = _icon
