extends Resource
class_name SongData


# The name of the json the data is loaded from, can also be nothing.
var file_name : String
# The directory the file is contained in.
var song_dir : String

# The songs name specified in the json file.
var song_name : String

# The songs BPM.
var bpm : float

# Whether the song should load the Voices file.
var use_voices : bool

# Characters.
var bf : String
var enemy : String
var gf : String

# The songs scroll speed.
var scroll_speed : float

# Every section in the song.
var sections : Array
var notes : Array


func load_chart(_directory : String, _chart_file : String, _simple = false) -> int:
	var _full_dir = _directory + _chart_file
	print("Attempting to load %s." % _full_dir)
	
	# Create a new file and load it.
	var _file = File.new()
	var _err = _file.open(_full_dir, File.READ)
	
	# Could not open the file.
	if _err != OK:
		return _err
	
	# The parsed json data in a dictionary.
	var _data = JSON.parse(_file.get_as_text())
	
	if _data.error != OK:
		return _data.error
		
	file_name = _chart_file
	song_dir = _directory
		
	return load_chart_data(_data.result, _simple)

# Load a external chart.
func load_chart_data(_data : Dictionary, _simple = false) -> int:
	var _song_data : Dictionary = _data["song"]
	
	# Update all the variables.
	song_name = _song_data.get("song")
	bpm = _song_data.get("bpm")
	use_voices = _song_data.get("needsVoices")
	
	bf = _song_data.get("player1")
	enemy = _song_data.get("player2")
	# gf
	
	var _speed = _song_data.get("speed")
	if Settings.custom_scroll_speed:
		_speed = Settings.scroll_speed
		print("Updated to custom scroll speed %s." % _speed)
	scroll_speed = sqrt(_speed)
	
	if !_simple:
		# Seperate the notes from the sections.
		var _temp_sections = _song_data.get("notes")
		for _section in _temp_sections:
			var _section_time = ((((60 / bpm) / 4) * 16) * sections.size()) * 1000
			var _must_hit = _section.get("mustHitSection", false)
			
			var _new_section = [_section_time, _must_hit]
			
			for _note in _section.get("sectionNotes"):
				if _section.get("mustHitSection", false) == false:
					if _note[1] < len(Chart.NoteDirs):
						_note[1] += len(Chart.NoteDirs)
					else:
						_note[1] -= len(Chart.NoteDirs)
				
				notes.append(_note)
			
			sections.append(_new_section)
		
		# Sort the notes array.
		notes.sort_custom(StrumTimeSorter, "sort_ascending")
	
	return 0

# Sort and array by its first values (the strum time probably).
class StrumTimeSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false
