extends Node2D
class_name Character, "res://Assets/Other/Editor/character.png"


signal taunted(_alt_key)


# Set the default animations for singing.
# The value should be the matching animation name in the AnimationPlayer.
export(Dictionary) var poses = {
	"idle": "idle",
	"dance-left": "dance-left",
	"dance-right": "dance-right",

	"left": "left",
	"down": "down",
	"up": "up",
	"right": "right",

	"left-miss": "left-miss",
	"down-miss": "down-miss",
	"up-miss": "up-miss",
	"right-miss": "right-miss",
	
	"hey": "hey",
}

# If the character should use dance-left and dance-right.
export(bool) var dancer = false
# Whether the miss animations should be used at all.
export(bool) var use_miss = true
# Swap the left and right directions.
export(bool) var flip_x = false
# If the character should replace girlfriend.
export(bool) var girlfriend_position = false

export(Color) var health_color = Color.yellow

export(AudioStreamOGGVorbis) var taunt_sound = preload("res://Assets/Sounds/hey.ogg")

export(Vector2) var position_offset

# The offset of the camera when this character is in focus.
# + x is right, + y is down.
export(Vector2) var camera_offset

# The icon to use for the character.
export(Resource) var icon_sheet

export(NodePath) var animation_player = NodePath("AnimationPlayer")

export(NodePath) var sprite = NodePath("Sprite")

# The last action used on this character.
# Used for keeping a animation held down.
var last_action : String

# The timer before the idle animation can be played.
var anim_timer : float

var anim_speed = 1

var created = false

var icon

var do_taunt_sound = true

var anim_prefix : String

var spawn_position: Vector2

# Godot ready function.
func _ready():
	animation_player = get_node_or_null(animation_player)
	sprite = get_node_or_null(sprite)
	
	var _beat_connect = Conductor.connect("beat_changed", self, "bop")
	
	setup_character()

func setup_character():
	pass

# Godot process function.
func _process(delta):
	if anim_timer > 0:
		anim_timer -= delta

# Play a animation from the poses dictionary.
func play(_anim_name : String, _anim_timer : float = 0) -> void:
	if flip_x:
		match _anim_name:
			"left":
				_anim_name = "right"
			"right":
				_anim_name = "left"
			"left-miss":
				_anim_name = "right-miss"
			"right-miss":
				_anim_name = "left-miss"
	
	var _animation = _anim_name
	if poses.has(_anim_name):
		_animation = poses[_anim_name]
	
	var _prefix = anim_prefix
	if not animation_player.has_animation(_animation + _prefix):
		_prefix = ""
	
	if animation_player.has_animation(_animation):
		animation_player.playback_speed = anim_speed
		
		animation_player.stop()
		animation_player.play(_animation + _prefix)
		
		anim_timer = _anim_timer

# Plays the idle animation every beat, unless the player is unable to.
func bop(_beat : int) -> void:
	if not can_bop():
		return
	
	if !dancer:
		if _beat % 2 == 1:
			play("idle")
	else:
		if animation_player.has_animation(poses["dance-left"]) && animation_player.has_animation(poses["dance-right"]):
			if fmod( abs(_beat), 2 ) == 1:
				play("dance-left")
			else:
				play("dance-right")
		else:
			play("idle")
	
	last_action = ""
	
func can_bop():
	if anim_timer > 0 || last_action != "" && Input.is_action_pressed(last_action):
		return false
	
	return true

func taunt(_alt_key = false):
	play("hey", 1)
	
	emit_signal("taunted", _alt_key)

func created_character():
	spawn_position = position
	
	var _pos_offset = position_offset
	if flip_x:
		_pos_offset.x = -_pos_offset.x
	
	position += _pos_offset
	
	if flip_x:
		scale.x = -scale.x
	
	created = true
