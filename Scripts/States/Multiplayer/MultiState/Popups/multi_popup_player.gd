extends MultiPopup

const CHARACTER_POPUP = preload("res://Scenes/States/Multiplayer/Popups/MultiCharPopup.tscn")
const SONG_POPUP = preload("res://Scenes/States/Multiplayer/Popups/MultiSongPopup.tscn")

onready var name_edit = $Card/Edit/EditPanel/ScrollContainer/Container/NameContainer/NameEdit

onready var character_label = $Card/Edit/EditPanel/ScrollContainer/Container/CharacterContainer/CharacterLabel
onready var song_label = $Card/Edit/EditPanel/ScrollContainer/Container/SongContainer/SongLabel
	
func _ready():
	update_ui()

func update_ui():
	name_edit.text = Settings.multi_data.get("name", "Boyfriend")
	character_label.text = Settings.multi_data.get("character", {}).get("character", "Default")
	song_label.text = Settings.multi_data.get("song", {}).get("song", "N/A")

	var _is_online = Settings.multi_data.get("character", {}).get("is_online")
	if _is_online:
		character_label.modulate = Color.blue
	else:
		character_label.modulate = Color.white

func _picked_character(_character):
	if _character == null:
		return
	
	Settings.multi_data.character = _character
	
	$Card.update_character()
	button.setup_character()
	
	update_ui()
	
func _picked_song(_song_data):
	if _song_data != null:
		Settings.multi_data.song = _song_data
	else:
		var _erased = Settings.multi_data.erase("song")
	
	update_ui()

func _on_NameEdit_text_changed(new_text):
	Settings.multi_data.name = new_text
	
func _on_DescriptionEdit_text_changed(new_text):
	Settings.multi_data.description = new_text

func _on_CharacterButton_pressed():
	var _popup = CHARACTER_POPUP.instance()
	_popup.connect("picked_character", self, "_picked_character")
	add_child(_popup)

func _on_SongButton_pressed():
	var _popup = SONG_POPUP.instance()
	_popup.connect("picked_song", self, "_picked_song")
	add_child(_popup)

func _on_ResetButton_pressed():
	Settings.multi_data = {}
	
	update_ui()
	button.setup_character()
	
	Settings.save_settings()
	
	queue_free()

func _on_MultiPlayerPopup_closed():
	Settings.save_settings()
