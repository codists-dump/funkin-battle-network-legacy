extends Node2D

export(int) var note

export(int) var frame setget set_frame

onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer

func _ready():
	var _rand = randi() % 2
	var _anim = str(_rand)
	
	animation_player.play(_anim)

func set_frame(_frame):
	if sprite != null:
		var _new_frame = _frame + (note * sprite.hframes)
		if _new_frame < sprite.hframes * sprite.vframes:
			sprite.frame = _new_frame
	
	frame = _frame

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
