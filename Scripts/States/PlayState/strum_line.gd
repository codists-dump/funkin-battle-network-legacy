extends Node2D
class_name StrumLine, "res://Assets/Other/Editor/strum_line.png"


# The scene used when creating the buttons.
const BUTTON_SCENE : PackedScene = preload("res://Scenes/States/PlayState/StrumArrow.tscn")

# The actions used for each button.
const BUTTON_ACTIONS : Array = [
	"left",
	"down",
	"up",
	"right",
]

# The animations used for each button.
const ANIM_ARRAY : Array = [
	"left",
	"down",
	"up",
	"right",
]

# The spacing between each button.
# Could be customizable?
export(float) var spacing = 160.0

# Whether player input should be recognized or not.
export(bool) var is_player = false

var offset = 0

# The scale for the notes.
# -1 will flip the directon the notes fall.
var note_scale : int = 1

# A reference to the character that last used this strum.
var character : Character

# Godot ready function.
func _ready():
	create_buttons()

# Godot process event.
func _process(_delta):
	# Bot play stuff.
	# Check each button for its latest note, if its past 0 ms then hit it.
	if !is_player:
		for _button in get_children():
			var _anim = _button.get_node("AnimationPlayer")
			
			# Make sure there are notes to check.
			if _button.get_node("Notes").get_child_count() > 0:
				var _note = _button.get_node("Notes").get_child(0)
				
				if _note != null:
					if (_note.strum_time - Conductor.song_position) <= 0 && !_note.bot_ignore:
						_note.note_hit()
						
						_button.hit_by_bot = true
						_anim.stop()
						_anim.play("hit")

# Create each of the strum buttons based on the chart singletons note directions.
# Makes it easier to add more keys.
func create_buttons() -> void:
	for _dir in len(Chart.NoteDirs):
		var _button = BUTTON_SCENE.instance()
		
		_button.position.x = _dir * spacing
		_button.note_type = _dir
		
		add_child(_button)
