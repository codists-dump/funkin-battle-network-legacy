tool
extends Control
class_name Alphabet, "res://Assets/Other/Editor/alphabet.png"

# The alignment enum.
enum X_Align {
	LEFT,
	CENTER,
	RIGHT
}

# The text to draw.
export(String, MULTILINE) var text setget set_text
# The alignment to use for drawing.
export(X_Align) var align

# The texture to use for drawing.
var texture : Texture = preload("res://Assets/Sprites/HUD/alphabet_sheet.png")
# The size of each letter in the sheet.
var texture_size : Vector2 = Vector2(88, 88)
# The position of each letter in the sheet.
var font_string = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.!?&()*+-<>\""
# How many frames there are per letter.
var frames : int = 2
# The speed each letters animation plays at.
var speed : float = 0.1
# The space between each letter.
var spacing : float = -40
# The space between each line break.
var y_spacing : float = -25

# The current frame for the letter.
var frame : int
# The timer between each new frame.
var frame_timer : float


func _process(delta):
	frame_timer += delta
	
	if frame_timer >= speed:
		frame_timer = 0
		frame += 1
		
		if frame >= frames:
			frame = 0
		
		if !Engine.editor_hint:
			update()
	
func _draw():
	var _fake_text = text
	var _line_breaks : Array
	
	rect_min_size = Vector2(0, 0)
	
	while _fake_text.find("\n") != -1:
		var _last_pos = 0
		if len(_line_breaks) > 0:
			_last_pos = _line_breaks.front()
		
		var _pos = _fake_text.find("\n", _last_pos+1)
		_fake_text.erase(_pos, 1)
		_line_breaks.append(_pos)
	
	for _char in len(_fake_text):
		var _char_pos = _char
		
		var _line_break = 0
		var _line_break_pos = 0
		var _next_line_break_pos = 0
		
		for _compare_line_index in len(_line_breaks):
			var _compare_line_break = _line_breaks[_compare_line_index]
			
			if _char > _compare_line_break-1:
				_line_break += 1
				_char_pos = _char - _compare_line_break
				
				_line_break_pos = _compare_line_break
		
		if len(_line_breaks) > _line_break:
			_next_line_break_pos = _line_breaks[_line_break]
		else:
			_next_line_break_pos = len(_fake_text)
		
		var _letter = _fake_text[_char].to_upper()
		var _letter_pos = font_string.find(_letter)
		
		var _line_text = _fake_text.substr(_line_break_pos, _next_line_break_pos-_line_break_pos)
		
		if _letter_pos == -1:
			continue
		
		var _x_pos = _char_pos * (texture_size.x + spacing)
		var _y_pos = _line_break * (texture_size.y + y_spacing)
		
		match align:
			X_Align.CENTER:
				_x_pos += (rect_size.x / 2) - (((len(_line_text) + 0.9) / 2) * (texture_size.x + spacing))
			X_Align.RIGHT:
				_x_pos += rect_size.x - ((len(_line_text) + 0.9) * (texture_size.x + spacing))
		
		var _rect = Rect2(Vector2(_x_pos, _y_pos), texture_size)
		var _source_rect = Rect2(Vector2(frame * texture_size.x, _letter_pos * texture_size.y), texture_size)
		
		draw_texture_rect_region(texture, _rect, _source_rect, Color.white)
		
		var _possible_size = Vector2((len(_line_text) + 0.9) * (texture_size.x + spacing), texture_size.y)
		if _possible_size.x > rect_min_size.x:
			rect_min_size = _possible_size


func set_text(value : String):
	text = value
	update()
