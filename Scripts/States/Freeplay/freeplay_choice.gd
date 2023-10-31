extends Alphabet

var icon : String = "dad"

func _ready():
	setup_icon()

func _process(_delta):
	$Icon.position.x = rect_min_size.x + 30

func setup_icon():
	var _character = load(Resources.characters[icon]).instance()
	$Icon.texture = _character.icon_sheet
