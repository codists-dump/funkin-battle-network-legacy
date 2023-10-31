extends CanvasLayer

var play_state

var _options = []

onready var is_host = get_tree().is_network_server()
onready var is_solo = play_state.is_solo

func _ready():
	play_state.set_process_unhandled_input(false)
	
	if not is_host:
		_options = ["resume", "leave game"]
	else:
#		if not is_solo:
#			_options = ["resume", "end song"]
#		else:
#			_options = ["resume", "restart song", "end song"]
		
		_options = ["resume", "end song"]
	
	if is_solo:
		var _solo_commands = []
		_options.append_array(_solo_commands)
	
	var _choice_menu = $Menu/ChoiceMenu
	_choice_menu.choices = _options
	_choice_menu.create_choices()
	
	setup_info()
	
func _exit_tree():
	play_state.set_process_unhandled_input(true)

func _unhandled_input(event):
	if event.is_action_pressed("cancel"):
		queue_free()

func setup_info():
	var _label = $Menu/Label
	
	var _dif_string = ["EASY", "NORMAL", "HARD"]
	
	var _info_text = ""
	var _song_name = play_state.song_name.replace("-", " ")
	_info_text += "%s (%s)" % [_song_name.capitalize(), _dif_string[play_state.song_difficulty]]
	_info_text += "\n%s" % [play_state.song_mod]
	
	var _players = []
	_info_text += "\n\nPLAYERS\n"
	for _player in play_state.playing_players:
		var _info = Multiplayer.player_info.get(_player, {})
		
		if _player == get_tree().get_network_unique_id():
			_info = Multiplayer.my_info
		
		_info_text += "%s\n" % _info.get("name", "unnamed")
	
	_label.text = _info_text

func _on_ChoiceMenu_option_selected(index):
	if !is_host:
		match index:
			0:
				queue_free()
			1:
				queue_free()
				
				Conductor.stop_music()
				Multiplayer.leave_game()
	else:
		match index:
			0:
				queue_free()
			1:
				queue_free()
				
				play_state.online_finished()
				play_state.rpc("online_finished")

#	if is_solo:
#		match index:
#			2:
#				queue_free()

func toggle_options(enabled : bool):
	$CanvasLayer/OptionsMenu/ChoiceMenu.set_process(enabled)
	$CanvasLayer/OptionsMenu/ChoiceMenu.set_process_unhandled_input(enabled)
	
	$CanvasLayer/OptionsMenu.visible = enabled
	
	$CanvasLayer/ChoiceMenu.set_process(!enabled)
	$CanvasLayer/ChoiceMenu.set_process_unhandled_input(!enabled)
	
	$CanvasLayer/ChoiceMenu.visible = !enabled
