extends Sprite
class_name XMLSprite

export(String) var xml_path

var animation_player = AnimationPlayer.new()

func _ready():
	setup_anim_player()
	add_sparrow_atlas()

func setup_anim_player():
	animation_player.root_node = "../../"
	add_child(animation_player)

func add_sparrow_atlas():
	texture = Mods.mod_image(xml_path + ".png")
	hframes = 1
	vframes = 1
	frame = 0

	region_enabled = true
	centered = false

func add_by_prefix(_name, _xml_name, _offset=[0,0], _fps=24, _loops=false, _indices = []):
	var anim = Animation.new()
	var box_track = anim.add_track(Animation.TYPE_VALUE)
	var offset_track = anim.add_track(Animation.TYPE_VALUE)
	
	anim.value_track_set_update_mode(box_track, Animation.UPDATE_DISCRETE)
	anim.track_set_path(box_track, name + ":region_rect")
	
	anim.value_track_set_update_mode(offset_track, Animation.UPDATE_DISCRETE)
	anim.track_set_path(offset_track, name + ":offset")
	
	var _use_indices = false
	if !_indices.empty():
		_use_indices = true
	
	var parser = XMLParser.new()

	var errorCode = parser.open(xml_path + ".xml")
	if errorCode != OK:
		return
	
	var time = 0.0
	var _last_name = null
	while parser.read() != ERR_FILE_EOF:
		if parser.get_attribute_count() > 0:
			var nName
			var x
			var y
			var w
			var h
			var fx
			var fy
			var fw
			var fh
			for i in range(parser.get_attribute_count()):
				match (parser.get_attribute_name(i)):
					"name":
						var newName = parser.get_attribute_value(i).left(len(parser.get_attribute_value(i)) - 4)
						var newNumber = parser.get_attribute_value(i).right(len(parser.get_attribute_value(i)) - 4)
						
						if (str(newName) != _xml_name):
							continue
						
						if _use_indices:
							if !_indices.has(float(newNumber)):
								continue
						
						nName = parser.get_attribute_value(i)
					"x":
						x = int(parser.get_attribute_value(i))
					"y":
						y = int(parser.get_attribute_value(i))
					"width":
						w = int(parser.get_attribute_value(i))
					"height":
						h = int(parser.get_attribute_value(i))
					"frameX":
						fx = int(parser.get_attribute_value(i))
					"frameY":
						fy = int(parser.get_attribute_value(i))
					"frameWidth":
						fw = int(parser.get_attribute_value(i))
					"frameHeight":
						fh = int(parser.get_attribute_value(i))
			
			if _last_name == nName:
				continue
			_last_name = nName
			
			var canAdd = true
			if (nName == null):
				canAdd = false
			
			if (canAdd):
				if (fx == null):
					fx = 0
				if (fy == null):
					fy = 0
				if (fw == null):
					fw = w
				if (fh == null):
					fh = h
				
				anim.track_insert_key(box_track, time, Rect2(x, y, w, h))
				anim.track_insert_key(offset_track, time, -Vector2(fx, fy) + Vector2(_offset[0], _offset[1]))
				time += 1.0/float(_fps)
	
	anim.loop = _loops
	anim.length = time
	
	animation_player.add_animation(_name, anim)

func play(_name):
	animation_player.play(_name)
