extends Node2D

var playstate_data : Dictionary

var do_bop : bool
var fading_out : bool

func _ready():
	Conductor.stop_music()
	var _bop = Conductor.connect("beat_changed", self, "bop")

func _process(_delta):
	$Camera.position = $Sprite.position
	
func _input(event):
	if event.is_action_pressed("confirm"):
		if !fading_out:
			Conductor.stop_music()
			$AnimationPlayer.play("retry")
			
			fading_out = true
		else:
			goto_playstate()
	
	if event.is_action_pressed("cancel"):
		if !fading_out:
			Conductor.stop_music()
			Main.change_scene_transition(Main.MAIN_MENU_SCENE)
			
			fading_out = true
		
func bop(beat : int):
	if beat % 2 == 0:
		if do_bop:
			$AnimationPlayer.stop()
			$AnimationPlayer.play("bop")
			
func goto_playstate():
	var _scene = Main.create_playstate(playstate_data["song_directory"], playstate_data["song_name"], playstate_data["song_difficulty"])
	Main.change_scene_transition(_scene)

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"die":
			do_bop = true
			
			bop(0)
			
			var _stream = load("res://Assets/Music/game_over.ogg")
			Conductor.play_song(_stream, null)
		"retry":
			goto_playstate()
