extends Control

# The song the main menu uses.
const MAIN_MENU_SONG = preload("res://Assets/Music/freaky_menu.ogg")

# If the title has been shown.
var shown_title : bool

# The frame the logo should use.
var logo_frame : float

# The funny easter egg.
var easter_egg : Node
# The step that the user is currently on to get the easter egg.
var easter_egg_step : int

# Godot ready function.
func _ready():
	$IntroText/NGLogo.visible = false
	$Title.visible = false
	
	if shown_title:
		start_title()
	else:
		Conductor.play_song(MAIN_MENU_SONG, null, 102)
	
	var _on_beat = Conductor.connect("beat_changed", self, "on_beat")

# Godot process function.
func _process(delta):
	if $Title/Flash.color.a > 0:
		$Title/Flash.color.a -= delta / 2
		
	if logo_frame < 3:
		logo_frame += delta * 24
	else:
		logo_frame = 3
	
	$Title/Logo.frame = logo_frame

# Godot input function.
func _input(event):
	if event.is_action_pressed("confirm"):
		if !shown_title:
			start_title()
		else:
			start_game()
	
	var _completed = easter_egg_input(event, [KEY_C, KEY_O, KEY_D, KEY_I, KEY_S, KEY_T])
	if _completed:
		easter_egg_spawn()

# Change the text on specific beats.
func on_beat(_beat : int):
	logo_frame = 0
	
	if fmod( abs(_beat), 2 ) == 1:
		$GFPlayer.play("dance_left")
	else:
		$GFPlayer.play("dance_right")
		
	if easter_egg != null:
		easter_egg.bop()
	
	if shown_title:
		return
		
	var _text = $IntroText/Alphabet
	
	match _beat:
		1:
			_text.text = "ninjamuffin99\nphantom arcade\nkawaisprite\nevilsk8er"
		3:
			_text.text += "\npresent"
		4:
			_text.text = ""
		5:
			_text.text = "In association\nwith"
		7:
			_text.text += "\nnewgrounds"
			$IntroText/NGLogo.visible = true
		8:
			_text.text = ""
			$IntroText/NGLogo.visible = false
		9:
			_text.text = "holy shit"
		11:
			_text.text += "\namong us"
		12:
			_text.text = ""
		13:
			_text.text = "FRIDAY"
		14:
			_text.text += "\nNIGHT"
		15:
			_text.text += "\nFUNKIN"
		16:
			start_title()

# Start the actual title bit.
func start_title():
	$IntroText.visible = false
	
	$Title.visible = true
	
	if !shown_title:
		$Title/Flash.color.a = 1
	
	shown_title = true

# Start the game.
func start_game():
	if $Timer.is_stopped():
		$EnterPlayer.play("pressed")
		$PressedStream.play()
		
		$Timer.start()

# The input for the easter egg.
func easter_egg_input(event, code):
	if event is InputEventKey:
		if event.pressed:
			var _correct = false
			
			if code[easter_egg_step] == event.scancode:
				if easter_egg_step == len(code) - 1:
					easter_egg_step = 0
					return true
				else:
					easter_egg_step += 1
					$EggStream.play()
			else:
				easter_egg_step = 0
	
	return false

# Spawn the easter egg.
func easter_egg_spawn():
	if easter_egg == null:
		$PressedStream.play()
		
		easter_egg = load("res://Scenes/States/Intro/IntroCodEasterEgg.tscn").instance()
		easter_egg.position = Vector2(1108, 430)
		easter_egg.scale = Vector2(0.9, 0.9)
		$Title.add_child_below_node($Title/GF, easter_egg)

# Actually goto the main menu.
func _on_Timer_timeout():
	Main.change_scene_transition(Main.MAIN_MENU_SCENE)
