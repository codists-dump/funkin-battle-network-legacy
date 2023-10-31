extends Control

func _ready():
	var _page_changed = $ChoiceMenu.connect("page_changed", self, "_page_changed")

func _process(_delta):
	var _pages = $ChoiceMenu.option_choices.keys()
	var _cur_page = $ChoiceMenu.page
	
	# Current page
	$TopBar/PageText.text = _pages[_cur_page]
	
	# Next page
	var _next_page = _cur_page + 1
	if _next_page > len(_pages)-1:
		_next_page = 0
	
	$TopBar/PageRightText.text = _pages[_next_page]
	
	# Last page
	var _last_page = _cur_page - 1
	if _last_page < 0:
		_last_page = len(_pages)-1
	
	$TopBar/PageLeftText.text = _pages[_last_page]
	
	# Animate the top bar.
	$TopBar.rect_position.x = lerp($TopBar.rect_position.x, 0, _delta * 10)
	
	# Get the data for the current option.
	var _cur_page_name = $ChoiceMenu.option_choices.keys()[_cur_page]
	var _cur_option_data = $ChoiceMenu.option_choices[_cur_page_name][$ChoiceMenu.selected]
	
	var _desc = ""
	if len(_cur_option_data) >= 3:
		_desc = _cur_option_data[2]
	
	$BotBar/BotLabel.text = _desc

func _page_changed(new_page):
	var _change = new_page - $ChoiceMenu.page
	$TopBar.rect_position.x = 400 * _change
