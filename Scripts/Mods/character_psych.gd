extends XMLCharacter
class_name PsychCharacter

export(String) var character_file

var json_data

func setup_character():
	image_file = character_file
	
	update_default_poses()
	load_json()
	load_icon()
	load_other()
	
	.setup_character()
	
	print("Loaded psych character " + character_file + ".")

func load_json():
	var _file = File.new()
	var _error = _file.open(character_dir + character_file + ".json", File.READ)
	
	if _error == OK:
		var _data = parse_json(_file.get_as_text())
		json_data = _data
	else:
		print("Could load character. %s" % _error)
		return
	
	for _anim in json_data.animations:
		var _anim_name = _anim.get("anim", "")
		var _xml_name = _anim.get("name", "")
		var _offset = _anim.get("offsets", [0, 0])
		var _indices = _anim.get("indices", [])
		var _loop = _anim.get("loop", false)
		var _fps = _anim.get("fps", 24)
		
		if _anim_name == "":
			continue
		
		# flip offsets idk why
		_offset[0] = -_offset[0]
		_offset[1] = -_offset[1]
		
		xml_anims[_anim_name] = {
			"name": _xml_name,
			"offset": _offset,
			"indices": _indices,
			"fps": _fps,
			"loop": _loop,
		}
		
	flip_x = json_data.get("flip_x", false)
	position_offset = Vector2(json_data.position[0], json_data.position[1])
	camera_offset = Vector2(json_data.camera_position[0], -json_data.camera_position[1])
	girlfriend_position = json_data.get("girlfriend_position", false)
	health_color = get_color(json_data.get("healthbar_colors", [255, 255, 255]))
	
	var _scale = json_data.get("scale", 1)
	scale = Vector2(_scale, _scale)

func load_icon():
	icon_sheet = Mods.mod_image(character_dir + "/icon-" + character_file + ".png")

func load_other():
	var _file = File.new()
	
	var _taunt_path = character_dir + "/emote.ogg"
	print(_taunt_path)
	if _file.file_exists(_taunt_path):
		taunt_sound = Mods.mod_ogg(_taunt_path)

func get_color(_color):
	return Color8(_color[0], _color[1], _color[2])

func update_default_poses():
	poses = {
		"idle": "idle",
		
		"dance-left": "danceLeft",
		"dance-right": "danceRight",

		"left": "singLEFT",
		"down": "singDOWN",
		"up": "singUP",
		"right": "singRIGHT",

		"left-miss": "singLEFTmiss",
		"down-miss": "singDOWNmiss",
		"up-miss": "singUPmiss",
		"right-miss": "singRIGHTmiss",
		
		"hey": "hey",
	}
