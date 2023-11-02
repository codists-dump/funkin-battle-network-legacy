extends Node2D

const WAITING_FOR_SCENE = preload("res://Scenes/States/Multiplayer/PlayState/MultiWaitingFor.tscn")

# The paths to the strums the PlayState pulls from.
export(NodePath) var player_strum
export(NodePath) var enemy_strum

# Countdown sound effects.
# here is the point where i have stopped caring about this project
# welcome :)
var countdown_sounds : Array = [
	load("res://Assets/Sounds/intro_3.ogg"),
	load("res://Assets/Sounds/intro_2.ogg"),
	load("res://Assets/Sounds/intro_1.ogg"),
	load("res://Assets/Sounds/intro_go.ogg"),
]

# The PlayState the hud is linked to.
# Used to call for info like health and junk.
var play_state : PlayState

var bop_mod = 4
var do_hud_bop = true

var hud_bop_scale = 0.02

var cam_bop_scale = 0.015

var shake_timer = 0
var shake_change_timer = 0
var shake_offset = Vector2(0, 0)

var icon_tween = Tween.new()

var waiting

onready var health_bar_pos = $HealthBar.rect_position

onready var middlescroll := Settings.middlescroll
onready var downscroll := Settings.downscroll

onready var showcase_mode := Settings.showcase_mode
onready var show_time_bar := Settings.time_bar


# Godot ready function.
func _ready():
	var _on_beat = Conductor.connect("beat_changed", self, "on_beat")
	$CountdownSprite.visible = false
	
	add_child(icon_tween)
	
	update_settings()
	
	update_info_bar()
	update_multi_info_bar()
	
	create_waiting()
	
	var _c_size_changed = get_tree().get_root().connect("size_changed", self, "_on_window_size_changed")
	_on_window_size_changed()

# Godot process function.
func _process(_delta):
	var _health_bar = $HealthBar
	var _icons = $HealthBar/Icons
	
	var _opponent_data = play_state.get_opponent_data()
	
	# health bar setup
	var _opponent_score = _opponent_data.get("score", 0)
	var _score_difference = play_state.score - _opponent_score
	if play_state.is_enemy:
		_score_difference = -_score_difference
	
	if !play_state.is_solo:
		_health_bar.value = (_score_difference / 250) + 50
	else:
		var _health = play_state.health
		if play_state.is_enemy:
			_health = 100 - (play_state.health)
		
		_health_bar.value = _health
	
	# icon stuffs
	_icons.position.x = -(_health_bar.value * (_health_bar.rect_size.x / 100)) + _health_bar.rect_size.x
	
	var _health_range = 20
	$HealthBar/Icons/Player.frame = int(_health_bar.value < _health_range)
	$HealthBar/Icons/Enemy.frame = int(_health_bar.value > 100 - _health_range)
	
	# shaker
	if shake_timer > 0:
		shake_change_timer += _delta
		if shake_change_timer > 0.05:
			var _magnitude = 4
			shake_offset = Vector2(rand_range(-_magnitude, _magnitude), rand_range(-_magnitude, _magnitude))
		
		shake_timer -= _delta
	else:
		shake_offset = Vector2(0, 0)
	
	$HealthBar.rect_position = health_bar_pos + shake_offset
	
	# lerp hud
	if do_hud_bop:
		self.scale = lerp(self.scale, Vector2(1, 1), 5 * _delta)
	
#	$LabelRating.text = ""
#	for _rating in play_state.hit_ratings.keys():
#		$LabelRating.text += _rating.to_upper() + " > " + str(play_state.hit_ratings[_rating]) + "\n"
#	if (play_state.missed_notes != 0):
#		$LabelRating.text += "MISS > " + str(play_state.missed_notes)
	
	# countdown fade
	if $CountdownSprite.modulate.a > 0:
		$CountdownSprite.modulate.a -= 4 * _delta

	if Conductor.music_stream.stream != null:
		$TimeBar.value = Conductor.music_stream.get_playback_position()
		$TimeBar.max_value = Conductor.music_stream.stream.get_length()
		$TimeBar/TimeLabel.text = get_time($TimeBar.max_value - $TimeBar.value)

func _on_window_size_changed():
	var _size = get_viewport_rect().size
	position = _size / 2

func get_time(_playback_seconds):
	var _seconds = int(_playback_seconds) % 60
	var _minutes = _playback_seconds / 60
	
	var _second_str = "%02d" % _seconds
	var _min_str = "%02d" % _minutes
	
	return "%s:%s" % [_min_str, _second_str]

# Function that runs every beat.
func on_beat(_beat : int) -> void:
	var _icons = $HealthBar/Icons
	var _enemy_icon = $HealthBar/Icons/Enemy
	var _player_icon = $HealthBar/Icons/Player
	
	var _speed = 0.2
	var _scale = 1.15
	var _offset = 3
	var _ease_type = Tween.TRANS_LINEAR
	var _ease_thi = Tween.EASE_IN
	icon_tween.interpolate_property(_icons, "scale", Vector2.ONE * _scale, Vector2.ONE, _speed, _ease_type, _ease_thi)
	icon_tween.interpolate_property(_enemy_icon, "offset:x", -_offset, 0, _speed, _ease_type, _ease_thi)
	icon_tween.interpolate_property(_player_icon, "offset:x", -_offset, 0, _speed, _ease_type, _ease_thi)
	
	icon_tween.start()
	
	var _alpha = 1
	if _beat <= 0:
		match abs(_beat % 5):
			4.0:
				if len(countdown_sounds) >= 1:
					$CountdownStream.stream = countdown_sounds[0]
					$CountdownStream.play()
			3.0:
				$CountdownSprite.visible = true
				
				if len(countdown_sounds) >= 2:
					$CountdownStream.stream = countdown_sounds[1]
					$CountdownStream.play()
				
				$CountdownSprite.frame = 0
				$CountdownSprite.modulate.a = _alpha
			2.0:
				if len(countdown_sounds) >= 3:
					$CountdownStream.stream = countdown_sounds[2]
					$CountdownStream.play()
				
				$CountdownSprite.frame = 1
				$CountdownSprite.modulate.a = _alpha
			1.0:
				if len(countdown_sounds) >= 4:
					$CountdownStream.stream = countdown_sounds[3]
					$CountdownStream.play()
				
				$CountdownSprite.frame = 2
				$CountdownSprite.modulate.a = _alpha
			0.0:
				$CountdownSprite.visible = false
	
	if do_hud_bop:
		if _beat % bop_mod == 0:
			self.scale = Vector2(1+hud_bop_scale, 1+hud_bop_scale)

# Update the info bar.
func update_info_bar() -> void:
	var _info_text = ""
	_info_text += "Score: " + str(play_state.score)
	
	var _total_miss = play_state.missed_notes + play_state.fake_missed_notes
	if play_state.fake_missed_notes == 0:
		_info_text += " | Misses: " + str(play_state.missed_notes)
	else:
		_info_text += " | Misses: " + str(play_state.missed_notes) + " (" + str(_total_miss) + ")"
	
	var _acc = get_accuracy(play_state.hit_notes, play_state.accuracy_sum)
	var acc_string = str(floor(_acc * 10000) / 100)
	
	var fc_string = ""
	if play_state.missed_notes == 0:
		fc_string = " | FC"
	
	_info_text += " | Rating: " + get_rating(_acc) + " [" + acc_string + "%" + fc_string + "]"
	
#	if play_state.timing_sum != 0:
#		_info_text += " | " + str(play_state.timing_sum / play_state.hit_notes)
	
	var _info_bar = $InfoContainer/InfoBar
	if play_state.is_enemy:
		_info_bar = $InfoContainer/InfoBar2
	
	var _my_id = get_tree().get_network_unique_id()
	
	if !Settings.simple_info:
		_info_bar.text = _info_text
	else:
		_info_bar.text = "Score: %s               Misses: %s" % [play_state.score, _total_miss]
	
	if play_state.is_team:
		_info_bar.text += "\n%s" % get_team_score()

func update_multi_info_bar():
	var _opponent_data = play_state.get_opponent_data()
	
	var _info_bar = $InfoContainer/InfoBar2
	if play_state.is_enemy:
		_info_bar = $InfoContainer/InfoBar
		
	if play_state.is_solo:
		_info_bar.visible = false
	
	var _score = _opponent_data.get("score", 0)
	var _misses = _opponent_data.get("misses", 0)
	var _hit_notes = _opponent_data.get("hit_notes", 0)
	var _accuracy_sum = _opponent_data.get("accuracy_sum", 0)
	
	var _acc = get_accuracy(_hit_notes, _accuracy_sum)
	var _acc_string = str(floor(_acc * 10000) / 100) + "%"
	
	var _rating = get_rating(_acc)
	
	var _fc_string = ""
	if _misses == 0:
		_fc_string = " | FC"
	
	if !Settings.simple_info:
		_info_bar.text = "Score: %s | Misses: %s | Rating: %s [%s%s]" % [_score, _misses, _rating, _acc_string, _fc_string]
	else:
		_info_bar.text = "Score: %s               Misses: %s" % [_score, _misses]
		
	if play_state.is_team:
		_info_bar.text += "\n%s" % get_team_score(false)

# Update the icons being used for the health bar
func update_health_icons() -> void:
	if play_state.player_character != null:
		$HealthBar/Icons/Player.texture = play_state.player_character.icon_sheet
		play_state.player_character.icon = $HealthBar/Icons/Player
	
	if play_state.enemy_character != null:
		$HealthBar/Icons/Enemy.texture = play_state.enemy_character.icon_sheet
		play_state.enemy_character.icon = $HealthBar/Icons/Enemy
	
	$HealthBar.tint_under = play_state.enemy_character.health_color
	$HealthBar.tint_progress = play_state.player_character.health_color
	
# Set stuff based on the players settings.
func update_settings():
	var _player_strum_node = get_node(player_strum)
	var _enemy_strum_node = get_node(enemy_strum)
	
	var _self_strum = _player_strum_node
	var _opponent_strum = _enemy_strum_node
	if play_state.is_enemy:
		_self_strum = _enemy_strum_node
		_opponent_strum = _player_strum_node
	
	# default settings
	_player_strum_node.position = Vector2(146, -255)
	_enemy_strum_node.position = Vector2(-494, -255)
	
	_player_strum_node.note_scale = 1
	_enemy_strum_node.note_scale = 1
	
	$HealthBar.rect_position = Vector2(-301, 276)
	$InfoContainer.rect_position = Vector2(-640, 306)
	$TimeBar.rect_position = Vector2(-123.5, -336)
	
	$HealthBar.visible = true
	$InfoContainer.visible = true
	$TimeBar.visible = true
	
	# change based on settings
	if downscroll:
		_player_strum_node.position.y = -_player_strum_node.position.y
		_enemy_strum_node.position.y = -_enemy_strum_node.position.y
		
		_player_strum_node.note_scale = -1
		_enemy_strum_node.note_scale = -1
		
		$HealthBar.rect_position.y = -276
		$InfoContainer.rect_position.y = -315
		$TimeBar.rect_position.y = 320
		
	if middlescroll:
		_self_strum.position.x = -160
		_opponent_strum.visible = false
	
	if showcase_mode:
		$HealthBar.visible = false
		$InfoContainer.visible = false
		$TimeBar.visible = false
	
	if not show_time_bar:
		$TimeBar.visible = false
	
	# update vars
	health_bar_pos = $HealthBar.rect_position


func shake_bar():
	shake_timer = 0.2

func get_team_score(_mine=true):
	var _total_score = 0
	if _mine:
		_total_score += play_state.score
	
	var _my_id = get_tree().get_network_unique_id()
	var _my_role = play_state.multiplayer_game_data.roles.get(_my_id, 0)
	
	if !_mine:
		if _my_role == 0:
			_my_role = 1
		elif _my_role == 1:
			_my_role = 0
	
	var _members = 0
	for _player in play_state.playing_players:
		var _role = play_state.multiplayer_game_data.roles.get(_player, 0)

		if _role == _my_role:
			var _info = play_state.player_data.get(_player, {})
			var _score = _info.get("score", 0)
			
			_total_score += _score
			_members += 1
			
	return _total_score / _members

# Get the current accuracy.
func get_accuracy(_hit_notes, _accuracy_sum) -> float:
	return play_state.get_accuracy(_hit_notes, _accuracy_sum)

# Get the current rating.
func get_rating(_accuracy) -> String:
	var _rating = "N/A"
	var _rating_array = {"S": 100, "A+": 95, "A": 85, "B+": 77.5, "B": 72.5, "C+": 67.5, "C": 62.5, "D+": 57.5, "D": 52.5, "E": 45, "F": 20}
	
	var _acc = null
	
	if play_state.hit_notes != 0:
		_acc = _accuracy * 100
		
		for _cur_rating in _rating_array.keys():
			if (_acc >= _rating_array[_cur_rating]):
				_rating = _cur_rating
				break
	
	return _rating

func create_waiting():
	waiting = WAITING_FOR_SCENE.instance()
	add_child(waiting)
	
	hide_waiting()

func show_waiting(_text = "Waiting for player(s)..."):
	waiting.get_node("Main").visible = true
	waiting.get_node("Main/Label").text = _text
	
func hide_waiting():
	waiting.get_node("Main").visible = false
