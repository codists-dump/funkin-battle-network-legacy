extends Node2D

enum BUTTON_STATE {NONE, NONE_PRESSED, PRESSED}

const PLAYER_POPUP = preload("res://Scenes/States/Multiplayer/MultiState/Popups/PlayerPopup.tscn")
const GAME_POPUP = preload("res://Scenes/States/Multiplayer/MultiState/Popups/GamePopup.tscn")

const PIZZA_BUTTON = preload("res://Scenes/States/Multiplayer/MultiState/Buttons/PizzaButton.tscn")

var selected_button = null
var cam_offset = Vector2(0, 0)

var hud = CanvasLayer.new()

func _ready():
	add_child(hud)

func _process(_delta):
	camera_move(_delta)
	
	for _button in $Buttons.get_children():
		_button.set_process_unhandled_input(selected_button == null)
		set_process_unhandled_input(selected_button == null)
		
		_button.selected = (selected_button == _button)

func _unhandled_input(event):
	if event.is_action_pressed("cancel"):
		Main.change_scene_transition(Main.MAIN_MENU_SCENE)
	
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_P:
				var _pizza = PIZZA_BUTTON.instance()
				_pizza.position.y = -1000
				add_child(_pizza)
			if event.scancode == KEY_1:
				_on_GameButton_pressed()
			if event.scancode == KEY_2:
				_on_PlayerButton_pressed()

func camera_move(_delta):
	var _position = get_global_mouse_position()
	var _divider = 25

	var _cam_pos = Vector2(0, 0)
	var _scale = Vector2(1.6, 1.6)
	
	if selected_button != null:
		_cam_pos = selected_button.position + selected_button.offset
		_scale = Vector2(0.8, 0.8)
		
	$Camera.position = _cam_pos
	$Camera.offset = lerp($Camera.offset, _position / _divider, _delta*5)
	$Camera.zoom = lerp($Camera.zoom, _scale, _delta*4)


func button_selected(_button):
	selected_button = _button
	
func button_unselected(_button):
	selected_button = null


func _on_PlayerButton_pressed():
	var _button = $Buttons/PlayerButton
	button_selected(_button)
	
	var _popup = PLAYER_POPUP.instance()
	_popup.connect("closed", self, "button_unselected", [_button])
	_popup.button = _button
	hud.add_child(_popup)

func _on_GameButton_pressed():
	var _button = $Buttons/GameButton
	button_selected(_button)
	
	var _popup = GAME_POPUP.instance()
	_popup.connect("closed", self, "button_unselected", [_button])
	_popup.button = _button
	hud.add_child(_popup)
