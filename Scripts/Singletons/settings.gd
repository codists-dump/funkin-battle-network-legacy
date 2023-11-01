extends Node

# Turns on sounds when a note is hit.
var hit_sounds : bool = false
# How loud said hitsounds should be.
var hit_sound_volume : float = -15
# If the notes will move downward instead of up.
var downscroll : bool = false
# Moves the strum line to the center of the screen.
var middlescroll : bool = false
# Allow custom scrollspeed.
var custom_scroll_speed : bool = false
# Change the scrollspeed to a specific amount.
var scroll_speed : int = 2

# Toggles the animation that appears when you get a sick.
var note_splashes : bool = true
# Displays the ratings on the hud instead of on the stage.
var hud_ratings : bool = false
# Hides unimportant game elements such as ratings and the health bar.
var showcase_mode : bool = false 
# Displays the time as a bar on the top of the screen.
var time_bar : bool = true
# Makes the score bar more simple.
var simple_info : bool = false
# Do the camera movement on note hit.
var cam_movement : bool = true

# The players multiplayer data.
var multi_data : Dictionary

# The users offset. (ms)
# NEGATIVE IS LATE BTW
var offset : float = 0

# Set the max FPS. Sets automatically on boot.
var fps_max : int setget set_fps
# Set whether or not the game uses vsync. Sets automatically on boot.
var v_sync : bool setget set_vsync
# Set the game to fullscreen.
var full_screen : bool setget set_fullscreen

# Godot ready function.
func _ready():
	fps_max = Engine.get_target_fps()
	v_sync = OS.vsync_enabled
	
	load_settings()

func _notification(_what):
	if _what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_settings()

# SAVING / LOADING FUNCTIONS

func save_settings():
	var file = ConfigFile.new()
	
	var propertys = get_script().get_script_property_list()
	for property in propertys:
		var propName = property["name"]
		file.set_value("settings", propName, get(propName))
	
	file.save("user://settings.ini")
	
	print("Saved settings.")
	
	save_keybinds()
	
func save_keybinds():
	var file = ConfigFile.new()
	
	var actions = InputMap.get_actions()
	for action in actions:
		var actionList = InputMap.get_action_list(action)
		var lastKey = actionList[actionList.size()-1]
		
		if (lastKey is InputEventKey):
			file.set_value("keybinds", action, actionList[actionList.size()-1].scancode)

	file.save("user://keybinds.ini")
	
	print("Saved keybinds.")
	
func load_settings():
	var file = ConfigFile.new()
	var err = file.load("user://settings.ini")
	
	if err != OK:
		return
		
	for key in file.get_section_keys("settings"):
		set(key, file.get_value("settings", key, get(key)))
	
	print("Loaded settings.")
	
	load_keybinds()

func load_keybinds():
	var file = ConfigFile.new()
	var err = file.load("user://keybinds.ini")
	
	if err != OK:
		return
		
	for action in file.get_section_keys("keybinds"):
		var keys = InputMap.get_action_list(action)
		
		if (keys.size() != 0):
			var scancode = file.get_value("keybinds", action, keys[keys.size()-1].scancode)

			var key = InputEventKey.new()
			key.set_scancode(scancode)
			
			InputMap.action_erase_event(action, keys[keys.size()-1])
			InputMap.action_add_event(action, key)
	
	print("Loaded keybinds.")

# SETGET

# Update the FPS when the max fps is changed.
func set_fps(value):
	fps_max = value
	Engine.set_target_fps(fps_max)

# Update whether or not Vsync should be used.
func set_vsync(value):
	v_sync = value
	OS.set_use_vsync(v_sync)

# Update fullscreen.
func set_fullscreen(value):
	full_screen = value
	OS.window_fullscreen = value
