extends Node2D

# The texture to use for the combo numbers
export var number_texture = preload("res://Assets/Sprites/HUD/combo.png")

# The sprites corresponding to each rating.
var rating_sprites : Dictionary = {
	"sick": 4,
	"good": 3,
	"bad": 2,
	"shit": 1,
	
	"miss": 0
}

# The rating that was hit to spawn this object.
var rating : String
# The combo when this rating was displayed.
var combo : int

# The current vertical speed.
var vsp : float = -140.0
# The current horizontal speed.
var hsp : float

# The amount of gravity to apply.
var gravity : float = 500

# Contains the current speeds of the numbers.
var number_vsps : Array

func _ready():
	var _hsp_amount = 10
	hsp = rand_range(-_hsp_amount, _hsp_amount)
	
	if rating_sprites.has(rating):
		$Sprite.frame = rating_sprites[rating]
	
	if rating != "miss":
		create_numbers()

func _process(delta):
	vsp += gravity * delta
	
	position.y += vsp * delta
	position.x += hsp * delta

	if vsp >= 150:
		modulate.a -= 5 * delta
		
	if modulate.a < 0:
		queue_free()
		
	move_numbers(delta)

# Move each combo number seperately.
func move_numbers(delta):
	var index = 0
	for child in get_children():
		if (index == 0):
			index += 1
			continue
		
		child.position += number_vsps[index-1] * delta
		number_vsps[index-1].y += (gravity / 4) * delta
		
		index += 1

# Create all the combo numbers.
func create_numbers():
	var _combo_len = len(str(combo))
	var _true_length = _combo_len
	
	var _sep = -40
	
	if (_combo_len < 3 && combo >= 0):
		_combo_len = 3
	
	for i in range(_combo_len):
		var _pos = Vector2(_sep * i, 0)
		var _number = str(combo).substr(_true_length-(i+1), 1)
		create_number(_pos, _number)

# Create a single combo number.
func create_number(pos, number):
	var num = Sprite.new()
	num.texture = number_texture
	
	var _scl = Vector2(0.5, 0.5)
	var _off = Vector2(-50, 60)
		
	num.scale = _scl
	num.position = pos + _off
	
	num.hframes = 11
	num.vframes = 2
	if (number == "-"):
		num.frame = 0
	else:
		num.frame = int(number)+1
	
	var _new_vsp = vsp / 2
	number_vsps.append(Vector2(rand_range(-0.2, 0.2), rand_range(_new_vsp - 35, _new_vsp + 35)))
	
	add_child(num)
