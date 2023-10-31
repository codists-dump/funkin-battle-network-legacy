extends Node2D
class_name MultiButton

signal mouse_entered()
signal mouse_exited()

signal pressed()

export var offset = Vector2.ZERO

var hovering = false
var previous_hovering = hovering

var selected = false

var hit_box : Rect2

func _unhandled_input(_event):
	if _event is InputEventMouseMotion:
		var _mouse = get_local_mouse_position()
		hovering = hit_box.has_point(_mouse)
	
		if hovering != previous_hovering:
			if hovering == true:
				mouse_entered()
			else:
				mouse_exited()
		
		previous_hovering = hovering
	
	if hovering:
		if _event is InputEventMouseButton:
			if _event.button_index == BUTTON_LEFT:
				if _event.pressed:
					pressed()

func pressed():
	emit_signal("pressed")

func mouse_entered():
	emit_signal("mouse_entered")
	
func mouse_exited():
	emit_signal("mouse_exited")

func hitbox_from_sprite(_sprite, _extra_scale = 1):
	# setup hitbox
	var _size = _sprite.texture.get_size() * _sprite.scale * _extra_scale
	var _pos = _sprite.position - _size/2
	hit_box = Rect2(_pos, _size)
