extends Node2D

func _input(event):
	
		if event.is_action_pressed("cancel"):
			if $OptionsMenu/ChoiceMenu.allow_input:
				$CancelStream.play()
				
				Main.change_scene_transition(Main.MAIN_MENU_SCENE)
			else:
				$OptionsMenu/ChoiceMenu.allow_input = true
