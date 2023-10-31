extends Node

# DESCRIPTION:
# Most music related stuff is in here.
# Its how you play songs with BPM and stuff.
# DATE CREATED:
# 2022-04-04 (nice)


# Emitted when the song starts playing.
signal song_playing()

# Emitted every time the step has changed.
signal step_changed(step)
# Emitted every time the beat has changed.
signal beat_changed(beat)


# The AudioStreamPlayer's that are used to play the games music.
var music_stream : AudioStreamPlayer
var vocal_stream : AudioStreamPlayer

# The current position of the song, never use music_stream.get_position or whatever it doesn't "work".
var song_position : float

# The current songs BPM.
var bpm : float

# A quarter-note based on the BPM. (in ms)
# Used in other calculations.
var crochet : float
# A step based on the BPM. (This is probably wrong, I dont know music stuff...)
var step_crochet : float

# The current step.
var cur_step : float
# The last step.
var last_step : float

# The current beat.
var cur_beat : float
# The last beat.
var last_beat : float

# Whether or not to actually use a countdown.
var use_countdown : bool
# The tiemr before the song actually starts.
var countdown_offset : float

# Used to mute vocals when the player misses during gameplay.
var mute_vocals : bool


# Godot ready function.
func _ready():
	create_music_nodes()

# Godot process function.
func _process(_delta):
	# Countdown stuff.
	if use_countdown:
		countdown_offset -= _delta * 1000
		
		if countdown_offset <= 0:
			use_countdown = false
			play_music()
	
	update_song_position()

	# Update the current beat and step.
	update_step()
	
	# Mute the vocals and stuff.
	if mute_vocals:
		vocal_stream.volume_db = -80
	else:
		vocal_stream.volume_db = 0
		
func update_song_position():
	# Get the accurate position of the song from the music stream.
	# More information on why I need to do this here: https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html
	song_position = music_stream.get_playback_position() + AudioServer.get_time_since_last_mix()
	song_position -= AudioServer.get_output_latency()
	# Convert to ms.
	song_position *= 1000.0
	
	# Do offset stuff.
	song_position -= Settings.offset
	song_position -= countdown_offset

# Create the music and vocal stream nodes as a child of the Conductor.
func create_music_nodes() -> void:
	# Setup Music Stream stuff.
	music_stream = AudioStreamPlayer.new()
	music_stream.name = "MusicStream"
	music_stream.bus = "Music"

	# Setup Vocal Stream stuff.
	vocal_stream = AudioStreamPlayer.new()
	vocal_stream.name = "VocalStream"
	vocal_stream.bus = "Vocals"

	# Add the nodes as children.
	add_child(music_stream, true)
	add_child(vocal_stream, true)

# Change the BPM and the crochet variables.
# Dont change the BPM from the variable, it will break stuff.
func change_bpm(_new_bpm : float) -> void:
	# Update the BPM.
	bpm = _new_bpm
	
	if bpm == 0:
		return

	# Update the crochets.
	crochet = (60 / bpm) * 1000.0
	step_crochet = crochet / 4

# Updates the cur_step and last_step variables.
# Will send a signal when its changed.
func update_step() -> void:
	# Make sure the step crochet isn't 0 so a 0 division doesn't break everything.
	if step_crochet == 0:
		return

	# Update the step.
	cur_step = floor(song_position / step_crochet)

	# The step has changed.
	if cur_step > last_step:
		emit_signal("step_changed", cur_step)
		
		# The beat has changed.
		if fmod(cur_step, 4) == 0:
			cur_beat = cur_step / 4
			
			if cur_beat > last_beat:
				emit_signal("beat_changed", cur_beat)
			
			last_beat = cur_beat

	# Update the last step.
	last_step = cur_step

# Play a song with BPM values and such.
func play_song(_music : AudioStream, _vocals : AudioStream = null, _bpm : float = 100, _countdown : int = 0) -> void:
	# Apply the audio to the correct stream players.
	music_stream.stream = _music
	vocal_stream.stream = _vocals
	
	# Change the BPM.
	change_bpm(_bpm)
	
	use_countdown = _countdown != 0
	
	if !use_countdown:
		play_music()
	else:
		countdown_offset = (step_crochet * _countdown) * _countdown
		
	mute_vocals = false

# Play the current song.
func play_music():
	music_stream.play()
	vocal_stream.play()

	emit_signal("song_playing")

# Stop the current song.
func stop_music():
	use_countdown = false
	
	music_stream.stop()
	vocal_stream.stop()
	
func reset_music():
	music_stream.stop()
	vocal_stream.stop()
	
	music_stream.seek(0)
	vocal_stream.seek(0)
	
	countdown_offset = (step_crochet * 5) * 5
	update_song_position()
	
func skip_music(_seconds):
	music_stream.seek(_seconds)
	vocal_stream.seek(_seconds)
	
	update_song_position()
