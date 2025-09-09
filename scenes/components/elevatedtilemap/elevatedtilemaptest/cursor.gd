extends Sprite2D

@onready var elevated_tile_map: ElevatedTileMap = $"../ElevatedTileMap";

var cursor_position = Vector2i(0,0);

func _ready() -> void:
	global_position = elevated_tile_map.map_to_global(cursor_position);

func _process(delta: float) -> void:
	var changed = false;
	if Input.is_action_just_pressed("ui_left"):
		cursor_position.x -= 1;
		changed = true;
	elif Input.is_action_just_pressed("ui_right"):
		cursor_position.x += 1;
		changed = true;
	elif Input.is_action_just_pressed("ui_up"):
		cursor_position.y -= 1;
		changed = true;
	elif Input.is_action_just_pressed("ui_down"):
		cursor_position.y += 1;
		changed = true;
	if changed:
		cursor_position.x = min(max(0, cursor_position.x), 24);
		cursor_position.y = min(max(0, cursor_position.y), 24);
		global_position = elevated_tile_map.map_to_global(cursor_position);
	
