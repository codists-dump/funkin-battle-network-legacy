extends Node

signal got_song_data(song_data, inst)

var mutex
var semaphore
var thread

var chart_dir = "res://Assets/Songs/"
var chart_file = "tutorial-hard.json"

var exit_thread = false
var thread_busy = false

func _exit_tree():
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	
	semaphore.post()
	
	thread.wait_to_finish()

func ready_thread():
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	
	thread = Thread.new()
	thread.start(self, "thread_function")

func thread_function():
	while true:
		semaphore.wait()
		
		mutex.lock()
		var should_exit = exit_thread
		mutex.unlock()
		
		if should_exit:
			break
			
		mutex.lock()
		thread_busy = true
		
		var _dir = chart_dir
		var _file = chart_file
		mutex.unlock()
			
		var _chart = SongData.new()
		var _error = _chart.load_chart(_dir, _file)
		
		if _error == OK:
			var _inst_stream = ResourceLoader.load(_chart.song_dir + "Inst.ogg")
			
			emit_signal("got_song_data", _chart, _inst_stream)
		else:
			emit_signal("got_song_data", null, null)
		
		mutex.lock()
		thread_busy = false
		mutex.unlock()

func get_song_data(_directory, _file_name):
	chart_dir = _directory
	chart_file = _file_name
	
	semaphore.post()
