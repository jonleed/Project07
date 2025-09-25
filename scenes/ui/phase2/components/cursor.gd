class_name Cursor
extends Node2D

@onready var terrain_tile_map: TerrainTileMap = $"../TileMapGenerator/TerrainTileMap";

var cursor_position := Vector2(0, 0);
var cursor_position_int: Vector2i:
	get:
		return Vector2i(floor(cursor_position.x), floor(cursor_position.y));

func _ready() -> void:
	var res = terrain_tile_map.surface_to_global(cursor_position_int);
	if res != null:
		global_position = res;

func _unhandled_input(event):
	# Mouse Movement
	if event is InputEventMouseMotion:
		var mouse_global = (event.global_position)
		var surface_position = terrain_tile_map.global_to_surface(mouse_global);
		if surface_position != null:
			cursor_position = Vector2(surface_position.x, surface_position.y);
		
	# Select input
	# ToDo: Finalize Input Map and replace with dedicated inputs
	elif event.is_action_pressed("ui_accept") \
	or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		emit_signal("select_pressed", cursor_position)
		get_tree().root.set_input_as_handled()

func _process(delta: float) -> void:
	# Keyboard Movement
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	cursor_position += input_vector * delta * 10;
	cursor_position.x = min(max(0, cursor_position.x), 24);
	cursor_position.y = min(max(0, cursor_position.y), 24);
	var res = terrain_tile_map.surface_to_global(cursor_position_int);
	if res != null:
		global_position = res;
