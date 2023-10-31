extends Character
class_name XMLCharacter

export(String) var character_dir

export(String) var image_file

var xml_anims = {}

func setup_character():
	sprite = XMLSprite.new()
	
	animation_player = sprite.animation_player
	
	sprite.xml_path = character_dir + image_file
	add_child(sprite)
	
	for _anim in xml_anims:
		var _xml_anim = xml_anims[_anim]
		
		var _xml_name = _xml_anim.get("name", "")
		var _xml_offset = _xml_anim.get("offset", [0, 0])
		var _xml_fps = _xml_anim.get("fps", 24)
		var _xml_loop = _xml_anim.get("loop", false)
		var _xml_indices = _xml_anim.get("indices", [])
		
		if _xml_name == "":
			continue
		
		sprite.add_by_prefix(_anim, _xml_name, _xml_offset, _xml_fps, _xml_loop, _xml_indices)
	
	if xml_anims.has(poses["dance-left"]):
		dancer = true
	
	var _idle_name = "idle"
	if dancer:
		_idle_name = "dance-left"
	
	play(_idle_name)
	
	var _idle_anim = animation_player.get_animation(poses[_idle_name])
	if _idle_anim != null:
		var _region = _idle_anim.track_get_key_value(0, 0)
		if _region == null:
			return
		
		sprite.position -= _region.size / 2
