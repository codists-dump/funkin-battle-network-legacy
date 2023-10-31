extends Node
class_name MultiPopup

signal closed()

var button

func _unhandled_input(event):
	if event.is_action_pressed("cancel"):
		queue_free()
	
func _exit_tree():
	emit_signal("closed")
