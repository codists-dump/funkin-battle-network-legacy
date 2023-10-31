extends Node2D

# The song the main menu uses.
const MAIN_MENU_SONG = preload("res://Assets/Music/freaky_menu.ogg")
const BUTTON_SCENE = preload("res://Scenes/States/MainMenu/MainMenuButton.tscn")

var options = {"story": 3, "options": 2, "credits": 4}

var options_offset = Vector2(640, 150)

var selected = 0
var chose_option = false

func _ready():
	create_menu_objects()
	
	if !Conductor.music_stream.is_playing():
		Conductor.play_song(MAIN_MENU_SONG, null, 102)
	
func _process(_delta):
	if chose_option:
		return
	
	var _options_size = options.keys().size()
	var _offset = selected - (_options_size / 2)
	
	$Camera.position = Vector2(0, (_offset * 15))
	
	var _move = int(Input.is_action_just_pressed("down")) - int(Input.is_action_just_pressed("up"))
	
	if _move != 0:
		$Sounds/ScrollStream.play()
	
	if selected + _move < 0:
		_move = 0
		selected = options.size() - 1
	if selected + _move > options.size() - 1:
		_move = 0
		selected = 0
	
	selected += _move
	
	var _i = 0
	for _button in $Buttons.get_children():
		if _i == selected:
			_button.selected = true
		else:
			_button.selected = false
		
		_i += 1
	
	if Input.is_action_just_pressed("confirm"):
		var button = $Buttons.get_child(selected)
		button.get_node("AnimationPlayer").play("selected")
		$AnimationPlayer.play("pressed")
		
		var _o = 0
		for _other_buttons in $Buttons.get_children():
			if _o != selected:
				_other_buttons.visible = false
			
			_o += 1
			
		chose_option = true
		$Timer.start()
		
		$Sounds/ConfirmStream.play()
		
	if Input.is_action_just_pressed("cancel"):
		$Sounds/CancelStream.play()
		
		var _scene = load("res://Scenes/States/IntroState.tscn").instance()
		_scene.shown_title = true
		Main.change_scene_transition(_scene)
		
func create_menu_objects():
	var i = 0
	
	for _option in options:
		var _button = BUTTON_SCENE.instance()
		_button.type = options[_option]
		_button.position.y = (i * 140)
		_button.position += options_offset
		
		$Buttons.add_child(_button)
		
		i += 1

func option_logic(_name):
	match _name:
		"story":
			Main.change_scene_transition("res://Scenes/States/MultiState.tscn")
		"freeplay":
			Main.change_scene_transition("res://Scenes/States/FreeplayState.tscn")
		"options":
			Main.change_scene_transition("res://Scenes/States/OptionsState.tscn")
		_:
			var _reload = get_tree().reload_current_scene()

func _on_Timer_timeout():
	option_logic(options.keys()[selected])
