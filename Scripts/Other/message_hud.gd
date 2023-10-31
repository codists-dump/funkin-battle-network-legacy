extends CanvasLayer


func add_message(text):
	var alpha = Alphabet.new()
	alpha.text = text
	alpha.align = Alphabet.X_Align.CENTER
	$Text.add_child(alpha)
	
	var timer = Timer.new()
	alpha.add_child(timer)
	
	timer.connect("timeout", self, "_on_alpha_timeout", [alpha])
	timer.start(len(text) * 0.4)

func _on_alpha_timeout(alpha):
	alpha.queue_free()
