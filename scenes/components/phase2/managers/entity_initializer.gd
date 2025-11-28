extends TileMapLayer
class_name EntityInitializer

@export_subgroup("NODES")
@export var map_manager: MapManager
@export var trap_manager: Node
@export var turn_manager: Turn_Manager
@export var player_manager: Player_Unit_Manager
@export var enemy_manager: NPC_Manager
@export var cursor: Cursor
var initialized := false

@export_subgroup("ENTITIES")
#@export var player_entities:Array[UnitResource]
@export var enemy_entities: Array[UnitResource]
@export var trap_scenes: Array[PackedScene] = []  # <— drag any number of trap scenes here in the inspector

#the tiles that can spawn the player units
var player_tiles: Array[Vector2i] = []
#the tiles that spawn the enemy units correlated to which enemy units spawn there
var enemy_tiles: Dictionary[Vector2i,int] = {}
#the tiles that spawn the traps correlated to which traps spawn there
var trap_tiles: Dictionary[Vector2i,int] = {}


func _ready() -> void:
	#call_deferred("init_traps")
	await map_manager.ready
	get_tiles()
	init_player_units()
	#init_enemy_units()
	init_traps()
	player_manager.start()
	enemy_manager.start()
	turn_manager.start()
	map_manager._initialize_astar_grid()
	visible = false
	cursor.deselected.emit()


func get_tiles():
	#loop through all tiles in the layer
	var used_cells: Array[Vector2i] = get_used_cells()

	for cell_coords: Vector2i in used_cells:
		#get tile data of each tile
		var tile_data: TileData = get_cell_tile_data(cell_coords)
		if tile_data:
			#get player tiles, tiles that have the boolean value of Player Tile (custom data layer)
			var is_player: bool = tile_data.get_custom_data("Player Tile")
			if is_player:
				player_tiles.append(cell_coords)
				continue
			#get enemy tiles, tiles that dont have -1 as the value of Enemy Tile (custom data layer)
			var enemy_index: int = tile_data.get_custom_data("Enemy Tile")
			if enemy_index >= 0:
				enemy_tiles.set(cell_coords, enemy_index)
				continue
			#get trap tiles, tiles that dont have -1 as the value of Trap Tile (custom data layer
			var trap_index: int = tile_data.get_custom_data("Trap Tile")
			if trap_index >= 0:
				trap_tiles.set(cell_coords, trap_index)
				continue


##Returns the last Spawned Unit
func init_player_units():
	var party_size: int = Globals.party_units.size()
	if player_tiles.size() < party_size:
		printerr("Not enough player tiles for the party size. Not spawning player units")
		return
	player_tiles.shuffle()
	var arr: Array[UnitResource]
	for un in Globals.party_units:
		arr.append(un)
	print("Gotten Units: ", arr)
	#
	var tile: Vector2i
	var new_unit: Unit
	while not player_tiles.is_empty():
		if arr.is_empty():
			break
		tile = player_tiles.pop_at(randi_range(0, player_tiles.size() - 1))
		if map_manager.map_dict.get(tile) != null:
			printerr("Tried to spawn unit inside entity or wall skipping tile")
			continue
		var chosen_res: UnitResource = arr.pop_front()
		new_unit = player_manager.create_unit_from_res(chosen_res)
		if new_unit:
			print("Successfully created new unit")
		else:
			print("could not make proper new unit with: ", chosen_res)
		##add unit manually
		print("Appending unit to tile: ", tile)
		player_manager.units.append(new_unit)
		map_manager.map_dict.set(tile, new_unit)
		new_unit.cur_pos = tile
		new_unit.global_position = map_manager.coords_to_glob(tile)

		await get_tree().process_frame
	await get_tree().process_frame
	#player_manager.add_unit(new_unit,inf_vec_arr[index])
	#player_manager.move_unit(new_unit,tile)
	#await get_tree().process_frame

	## Refresh GUI After Unit Initialization
	player_manager.refresh_gui()
	player_manager._on_unit_deselected()


func init_enemy_units():
	await get_tree().process_frame
	for tile: Vector2i in enemy_tiles:
		var chosen_res: UnitResource = enemy_entities[enemy_tiles.get(tile, 0)]
		var new_unit: Unit = enemy_manager.create_unit_from_res(chosen_res)
		## Commented out is strangely broken on MacOS
		#enemy_manager.add_unit(new_unit,Vector2i(-1,-1))
		#enemy_manager.move_unit(new_unit,tile)
		# Add unit like the player manager
		enemy_manager.units.append(new_unit)
		map_manager.map_dict.set(tile, new_unit)
		new_unit.cur_pos = tile
		new_unit.global_position = map_manager.coords_to_glob(tile)
		await get_tree().process_frame
		new_unit._ready()

func init_traps():
	if trap_manager == null:
		push_error("Trap Manager is NULL during init_traps()!")
		call_deferred("_init_trap")
		return
	print("[SpikeTrap] Trap initialized, manager = %s" % trap_manager)
	initialized = true

	for tile: Vector2i in trap_tiles:
		var trap_index := trap_tiles[tile]

		if trap_index < 0 or trap_index >= trap_scenes.size():
			printerr("Invalid trap index at tile: ", tile)
			continue
		
		var trap_res:PackedScene = trap_scenes[trap_index]
		if trap_res == null:
			printerr("Trap resource at index ", trap_index, " is null.")
			continue
		
		# instance and position the trap
		var trap_instance:Node2D = trap_res.instantiate()
		trap_manager.add_child(trap_instance)
		trap_instance.position = map_manager.coords_to_glob(tile)
		# add trap to map dictionary (so tiles know they are occupied)
		
		print("Spawned trap at ", tile)
		
		await get_tree().process_frame
