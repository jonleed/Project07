extends Node2D

@export var start_point: Node2D
@export var end_point: Node2D
@export var red_square: ColorRect
@export var dot_spacing: float = 0.0
@export var travel_speed: float = 150.0

var dots: Array[ColorRect] = []
var progress := 0.0
var total_distance := 0.0

func _ready():
	if not start_point or not end_point or not red_square:
		return
	if dot_spacing == 0.0 and red_square:
		dot_spacing = red_square.size.x*2 # Make spaces as big as a square
	red_square.visible = false

	total_distance = start_point.global_position.distance_to(end_point.global_position)
	var num_dots = int(total_distance / dot_spacing)

	for i in range(num_dots):
		var dot = red_square.duplicate()
		dot.visible = false
		add_child(dot)
		dots.append(dot)

func _process(delta):
	if dots.is_empty():
		return
	progress += travel_speed * delta
	var visible_dots = int(progress / dot_spacing)

	for i in range(min(visible_dots, dots.size())):
		if not dots[i].visible:
			var t = float(i) / float(dots.size())
			var pos = start_point.global_position.lerp(end_point.global_position, t)
			dots[i].global_position = pos - dots[i].size / 2.0
			dots[i].visible = true
