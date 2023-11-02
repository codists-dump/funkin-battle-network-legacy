extends FNFScript
class_name FNFStage


var player_character
var enemy_character
var gf_character


func _loaded_class():
	player_character = stage.player_character
	enemy_character = stage.enemy_character
	gf_character = stage.gf_character
	
	._loaded_class()


# Clears the background layers so you can create you own backgrounds.
# (Will be replaced by a proper stage system at some point probably not LOL)
func clear_background():
	var _bg_layer = stage.get_node_or_null("Background")
	
	if _bg_layer != null:
		_bg_layer.queue_free()
