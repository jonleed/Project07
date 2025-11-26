extends Control

@onready var hint_btn: TextureButton = $HintBTN
@onready var hint_screen = get_parent().hint_screen

func _ready():
	hint_btn.pressed.connect(show_hint)

func show_hint():
	hint_screen.set_visibility(true)
