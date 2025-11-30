class_name Escape_Layer
extends TileMapLayer

var survival_tiles = {}

@export var layer: int
@export var map_manager: MapManager

func _ready() -> void:
	#call_deferred("init_traps")
	await map_manager.ready
	get_tiles()
	map_manager.tiles_that_fulfill_escape_win_condition = survival_tiles

func get_tiles():
	#loop through all tiles in the layer
	var used_cells: Array[Vector2i] = get_used_cells()
	print(used_cells)

	for cell_coords: Vector2i in used_cells:
		#get tile data of each tile
		var tile_data: TileData = get_cell_tile_data(cell_coords)
		if tile_data:
			survival_tiles[cell_coords] = true
