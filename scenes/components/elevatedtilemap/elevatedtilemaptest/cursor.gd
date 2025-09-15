extends Polygon2D

@onready var terrain_tile_map: TerrainTileMap = $"../TileMapGenerator/TerrainTileMap";

var cursor_position: Vector2 = Vector2(0,0);
var cursor_position_int: Vector2i:
	get:
		return Vector2i(floor(cursor_position.x), floor(cursor_position.y));

func _ready() -> void:
	var res = terrain_tile_map.surface_to_global(cursor_position_int);
	if res != null:
		global_position = res;

func _process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	cursor_position += input_vector*delta*10;
	cursor_position.x = min(max(0, cursor_position.x), 24);
	cursor_position.y = min(max(0, cursor_position.y), 24);
	var res = terrain_tile_map.surface_to_global(cursor_position_int);
	if res != null:
		global_position = res;
