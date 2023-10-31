extends MultiButton

func _ready():
	hitbox_from_sprite($Sprite)

func _on_GameButton_mouse_entered():
	$Tooltip/AnimationPlayer.play("appear")

func _on_GameButton_mouse_exited():
	$Tooltip/AnimationPlayer.play("hide")
