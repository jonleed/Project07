extends Node

@onready var spawn_coords: Array[Vector2i] = []

@export var map_manager: MapManager
@export var player_ui: Node
@onready var unit_packed: PackedScene = preload("res://scenes/components/phase2/unit/Player Unit.tscn")
@export var ent_init:TileMapLayer

func _ready():
	ent_init.hide()
	player_ui.connect("unit_display_update", Callable(self, "_on_unit_display_update"))
	get_tiles()

func get_tiles():
	#loop through all tiles in the layer
	var used_cells: Array[Vector2i] = ent_init.get_used_cells()

	for cell_coords: Vector2i in used_cells:
		#get tile data of each tile
		var tile_data: TileData = ent_init.get_cell_tile_data(cell_coords)
		if tile_data:
			#get player tiles, tiles that have the boolean value of Player Tile (custom data layer)
			var is_player: bool = tile_data.get_custom_data("Player Tile")
			if is_player:
				spawn_coords.append(cell_coords)
				continue

func create_unit_from_res(res:UnitResource) -> Unit:
	var un: Unit = unit_packed.instantiate()
	$"Unit holder".add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.add_to_group("Player Unit")
	return un

func _on_unit_display_update(unit_array: Array):
	# Remove all existing player units
	#for old_unit in get_tree().get_nodes_in_group("Player Unit"):
		## Remove from MapManager if present
		#if map_manager.map_dict.has(old_unit.cur_pos):
			#map_manager.map_dict.erase(old_unit.cur_pos)
		#old_unit.queue_free()
	for unit in $"Unit holder".get_children():
		map_manager.map_dict.erase(unit.cur_pos)
		map_manager.update_astar_solidity(unit.cur_pos)
		unit.queue_free()
	
	var temp_coords:Array[Vector2i] = spawn_coords.duplicate()
	
	# Spawn in Units
	for i in range(unit_array.size()):
		var res: UnitResource = unit_array[i]
		var unit: Unit = create_unit_from_res(res)

		unit.scale = Vector2(4, 4)
		
		# Spawn on preset coordinates
		var coord: Vector2i = temp_coords.pick_random()
		temp_coords.erase(coord)
		if not map_manager.spawn_entity(unit, coord):
			printerr("Failed to spawn unit %s at %s" % [res.unit_name, coord])
		else:
			unit.cur_pos = coord
			unit.global_position = map_manager.coords_to_glob(coord)
			
