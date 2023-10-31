extends MultiButton

const WIFI_SPRITE = preload("res://Assets/Sprites/Multiplayer/wifi.png")

var character = {"character": "bf"}

var character_node

func _ready():
	setup_character()
		
func _unhandled_key_input(event):	
	if selected or hovering:
		var _sing_timer = 0.4
		
		if event.is_action_pressed("left"):
			character_node.play("left", _sing_timer)
		if event.is_action_pressed("down"):
			character_node.play("down", _sing_timer)
		if event.is_action_pressed("up"):
			character_node.play("up", _sing_timer)
		if event.is_action_pressed("right"):
			character_node.play("right", _sing_timer)
		if event.is_action_pressed("taunt"):
			character_node.play("hey", _sing_timer)
		
		if event is InputEventKey:
			if event.scancode == KEY_F1:
				if event.pressed:
					setup_character()
					character_node.play("idle", _sing_timer)
			
func _process(_delta):
	if character_node == null:
		return
	
	# setup hitbox
	var _size = character_node.sprite.region_rect.size * Vector2(abs(character_node.scale.x), abs(character_node.scale.y))
	var _pos = character_node.position - _size/2
	hit_box = Rect2(_pos, _size)
	
	offset.y = -hit_box.size.y / 2
	
	if character.get("is_online", false):
		character_node.sprite.modulate.a = 0.5
	else:
		character_node.sprite.modulate.a = 1
	
	# tooltip
	$Tooltip.position = Vector2((-_size.x/6), -_size.y - 30)

func setup_character(_char=Settings.multi_data.get("character", {})):
	character = _char
	
	if character_node != null:
		character_node.queue_free()
	
	var _char_data = Resources.get_character_data(character.get("character", "bf"))
	character_node = Resources.load_character(_char_data[0], _char_data[1])
	
	add_child(character_node)
	character_node.flip_x = !character_node.flip_x
	character_node.created_character()
	
	if character.get("is_online", false):
		var _wifi_sprite = Sprite.new()
		_wifi_sprite.texture = WIFI_SPRITE
		_wifi_sprite.position.y += 50
		character_node.add_child(_wifi_sprite)

func _on_PlayerButton_mouse_entered():
	$Tooltip/AnimationPlayer.play("appear")

func _on_PlayerButton_mouse_exited():
	$Tooltip/AnimationPlayer.play("hide")
