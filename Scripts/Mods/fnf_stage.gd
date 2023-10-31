extends FNFScript
class_name FNFStage

# Clears the background layers so you can create you own backgrounds.
# (Will be replaced by a proper stage system at some point probably not LOL)
func clear_background():
	var _bg_layer = stage.get_node_or_null("Background")
	
	if _bg_layer != null:
		_bg_layer.queue_free()
