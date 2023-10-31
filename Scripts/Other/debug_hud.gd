extends CanvasLayer

func _process(_delta):
	var _text = "FPS: " + str(Engine.get_frames_per_second())
	_text += "\nMEMORY: " + str(floor(OS.get_static_memory_usage() * 0.00000095367432)) + "mb"
	
	if OS.is_debug_build():
		_text += "\nDEBUG BUILD"
		
	if Conductor.music_stream.playing:
		_text += "\n\n"
		_text += "%s / %s" % [Conductor.cur_step, Conductor.cur_beat]
	
	$Label.text = _text
