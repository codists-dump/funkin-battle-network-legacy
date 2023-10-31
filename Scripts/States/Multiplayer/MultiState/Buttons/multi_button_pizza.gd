extends MultiButton

const COMBO_RATING = preload("res://Scenes/States/PlayState/Rating.tscn")

var velocity = Vector2.ZERO

var combo = 0

onready var floor_pos = 100

onready var gravity = rand_range(50, 60)

func _ready():
	hitbox_from_sprite($Sprite, 1.6)
	
func _process(delta):
	velocity.y += gravity * delta
	
	position.y += velocity.y
	
	if position.y >= floor_pos:
		position.y = floor_pos
		velocity.y = -velocity.y / 2
		
		if combo >= 10:
			$AudioStreamPlayer2.play()
		combo = 0

func _on_PizzaButton_mouse_entered():
	$Tooltip/AnimationPlayer.play("appear")

func _on_PizzaButton_mouse_exited():
	$Tooltip/AnimationPlayer.play("hide")


func _on_PizzaButton_pressed():
	velocity.y = -20
	position.y += velocity.y
	
	combo += 1
	
	if combo >= 10:
		$AudioStreamPlayer.play()
		
		var _rating = COMBO_RATING.instance()
		_rating.rating = "sick"
		_rating.combo = combo
		
		get_tree().current_scene.add_child(_rating)
		_rating.position = get_global_mouse_position()
