extends ChoiceMenu

signal page_changed(new_page)

var option_types = {
	"": load("res://Scenes/States/Options/OptionTypes/OptionButton.tscn"),
	"bool": load("res://Scenes/States/Options/OptionTypes/BoolOptionButton.tscn"),
	"number": load("res://Scenes/States/Options/OptionTypes/NumberOptionButton.tscn"),
	"string": load("res://Scenes/States/Options/OptionTypes/StringOptionButton.tscn"),
	"vector2": load("res://Scenes/States/Options/OptionTypes/Vector2OptionButton.tscn"),
	"color": load("res://Scenes/States/Options/OptionTypes/ColorOptionButton.tscn"),
	"action": load("res://Scenes/States/Options/OptionTypes/ActionOptionButton.tscn"),
}

# Where the choices for each page are got from.
# PAGE {
# 	["NAME", "SETTING", "DESCRIPTION"],
#   etc...
# }
var option_choices : Dictionary = {
	"GAMEPLAY": [
		["Hit Sounds", "hit_sounds", "fuck your ears.\ni hate them."],
		["Hit Sound Volume", "hit_sound_volume", "fuck you kuu."],
		["Downscroll", "downscroll", "If the notes should scroll downwards instead of up.\nDoesn't update immediately."],
		["Middlescroll", "middlescroll", "Moves the players strum line to the center of the screen.\nDoesn't update immediately."],
		["Custom Scroll Speed", "custom_scroll_speed", "replace the scorllsped in the song."],
		["Scroll Speed", "scroll_speed", "the value to rtepalce ity to."],
	],
	"APPEARENCE": [
		["Note Splashes", "note_splashes", "Toggles the splash animation that appears when you get a sick."],
		["Time Bar", "time_bar", "Shows the time at the top of the screen."],
		["HUD Ratings", "hud_ratings", "Display the ratings on the HUD layer instead of the GAME layer."],
		["Simple Info", "simple_info", "Display the score bar in a simpler format. ex. \nScore: 0     Misses: 0"],
		["Camera Movement", "cam_movement", "Moves the camera slightly on a note press."],
		["Showcase Mode", "showcase_mode", "Hides less important elements for recording showcases.\nElements like the ratings and the health bar.\nDoesn't update immediately."],
	],
	"MISC": [
		["Target FPS", "fps_max", "The maximum Frames Per Second.\nDoesn't use this value with V-Sync."],
		["V-SYNC", "v_sync", "Locks the Frames Per Second to your monitors refresh rate."],
		["Fullscreen", "full_screen", "Makes the game run it fullscreen.\nCan also be toggled with ALT+ENTER."],
		["Offset", "offset", "The offset.\nNEGATIVE IS LATE BTW"],
	],
#	"TEST": [
#		["Test Bool", "test_bool", "test bool"],
#		["Test Int", "test_int", "test integer"],
#		["Test Float", "test_float", "test float"],
#		["Test String", "test_string", "test string"],
#		["Test Vector2", "test_vector2", "test vector2"],
#		["Test Color", "test_color", "test color"],
#	],
}

var page = 0

# Godot process function.
func _process(_delta):
	var _i = 0
	for _choice in alphabet_node.get_children():
		if _i == selected:
			_choice.is_selected = true
			
			if !allow_input:
				_choice.rect_position.x = 60
			else:
				_choice.rect_position.x = 0
		else:
			_choice.is_selected = false
		
		_i += 1
		
# Godot input function.
func _unhandled_input(event):
	if !allow_input:
		return
	
	if event.is_action_pressed("right"):
		change_page(page + 1)
	if event.is_action_pressed("left"):
		change_page(page - 1)

# Create the choice objects.
func create_choices() -> void:
	for _existing_choice in alphabet_node.get_children():
		_existing_choice.queue_free()
	
	var _page_name = option_choices.keys()[page]
	choices = option_choices[_page_name]
	
	var _i = 0
	
	for _choice in option_choices[_page_name]:
		var _option_data = option_choices[_page_name][_i]
		
		var _option_name = _option_data[0]
		
		var _option_value
		var _option_property = ""
		var _option_properties = null
		var _option_override_type = null
		
		if len(_option_data) >= 2:
			_option_property = _option_data[1]
			_option_value = Settings.get(_option_property)
			
		if len(_option_data) >= 4:
			_option_properties = _option_data[3]
			
		if len(_option_data) >= 5:
			_option_override_type = _option_data[4]
		
		var _type = ""
		match typeof(_option_value):
			TYPE_INT, TYPE_REAL:
				_type = "number"
			TYPE_BOOL:
				_type = "bool"
			TYPE_STRING:
				_type = "string"
			TYPE_VECTOR2:
				_type = "vector2"
			TYPE_COLOR:
				_type = "color"
				
		if _option_override_type != null:
			_type = _option_override_type
				
		if !option_types.keys().has(_type):
			_type = ""
		
		var _scene = option_types[_type].instance()
		
		_scene.text = _option_name
		
		_scene.setting = _option_property
		_scene.menu = self
		
		_scene.name = str(_i)
		_scene.mouse_filter = MOUSE_FILTER_IGNORE
		
		if _option_properties != null:
			for property in _option_properties.keys():
				var _value = _option_properties[property]
				_scene.set(property, _value)
			
		alphabet_node.add_child(_scene)
		
		_i += 1

func option_selected():
	var _i = 0
	for _choice in alphabet_node.get_children():
		if _i == selected:
			_choice.selected()
		
		_i += 1
			
	.option_selected()

func change_page(new_page):
	emit_signal("page_changed", new_page)
	
	if new_page > len(option_choices)-1:
		new_page = 0
	if new_page < 0:
		new_page = len(option_choices)-1
	
	page = new_page
	selected = 0
	
	create_choices()
