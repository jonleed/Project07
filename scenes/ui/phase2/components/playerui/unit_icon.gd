extends PanelContainer

@onready var health_text:Texture2D = preload("res://assets/ui/healthicon.png")
@export var unit_text_rect:TextureRect
@export var health_container:BoxContainer
@export var unit_label:Label
const MAXICONS:int = 7

#func _ready()->void:
	#set_icon("res://assets/ui/jester.png")
	#set_health(5)

func load_unit(un:Unit):
	set_icon(un.icon_sprite)
	set_health(un.health)
	unit_label.text = un.unit_name

func set_icon(texture)->void:
	if texture is Texture2D:#given texture is a loaded texture2D
		unit_text_rect.texture = texture
	elif texture is String:#given texture is a filepath
		var val = load(texture)
		if val and val is Texture2D:
			unit_text_rect.texture = val

func set_health(hp:int):
	clear_health()
	for i:int in hp:
		if i<MAXICONS:
			health_container.add_child(create_health_icon())

func clear_health():
	for child in health_container.get_children():
		child.queue_free()

func create_health_icon()->TextureRect:
	var health_icon :TextureRect = TextureRect.new()
	health_icon.texture = health_text
	return health_icon
