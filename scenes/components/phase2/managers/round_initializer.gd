extends TileMapLayer
class_name RoundInitializer

@export_subgroup("NODES")
@export var map_manager: MapManager
@export var trap_manager: Node
@export var turn_manager: Turn_Manager
@export var enemy_manager: NPC_Manager
var initialized := false

@export_subgroup("Rounds")
@export var kills_to_win: int = 1
@export var spawn_interval: int = 1
@export var rounds: Array[RoundData] = []
var round_count: int = -1
var spawn_count: int = 0
var kill_count: int = 0

#the tiles that spawn the enemy units 
var spawn_tiles: Array[Vector2i] = []

signal turn_banner_update(text: String)
signal objective_update(count:int, total:int) 

func _ready() -> void:
	turn_manager.round_start.connect(_on_round_start)
	get_tiles()
	enemy_manager.update_kill_count.connect(kill_count_update)
	visible = false
	objective_update.emit(kill_count, kills_to_win)


func get_tiles():
	#loop through all tiles in the layer
	var used_cells: Array[Vector2i] = get_used_cells()

	for cell_coords: Vector2i in used_cells:
		var tile_data: TileData = get_cell_tile_data(cell_coords)
		if tile_data:
			#get enemy tiles, tiles that dont have -1 as the value of Enemy Tile (custom data layer)
			var enemy_index: int = tile_data.get_custom_data("Enemy Tile")
			if enemy_index >= 0:
				spawn_tiles.append(cell_coords)
				continue

func _on_round_start():
	round_count+=1
	if round_count % spawn_interval == 0 and round_count > 0: # Dont spawn at game start
		#print("Spawn Round ", round_count)
		spawn_round_enemies()
	else:
		#print("Not spawning this round")
		emit_signal("turn_banner_update", "Round " + str(round_count))
		pass

signal game_won(val:bool)
func kill_count_update(): 
	kill_count+=1 
	objective_update.emit(kill_count, kills_to_win) 
	printerr("KILL COUNT: ", kill_count)
	if kills_to_win <= kill_count: 
		game_won.emit(true)

func spawn_round_enemies():
	if spawn_count >= rounds.size():
		print("No Round Data for this round")
		if enemy_manager.units.is_empty():
			#game_won.emit(true)
			pass
		emit_signal("turn_banner_update", "Round " + str(round_count))
		return  # No data for this round
	if spawn_tiles.size() == 0:
		print("No spawn tiles found for enemies.")
		emit_signal("turn_banner_update", "Round " + str(round_count))
		return

	var round_data: RoundData = rounds[spawn_count]
	spawn_count += 1 
	
	if spawn_tiles.size() < round_data.units.size():
		
		print("Not enough spawn tiles for the enemy units.")
		emit_signal("turn_banner_update", "Round " + str(round_count))
		return
	
	var available_tiles: Array = spawn_tiles.duplicate()
	available_tiles.shuffle()

	var arr: Array[UnitResource] = round_data.units.duplicate()
	print("Enemy units to spawn: ", arr)
	emit_signal("turn_banner_update", "Round " + str(round_count) + " Spawning: " + str(arr.size()))

	var tile: Vector2i
	var new_unit: Unit

	while not available_tiles.is_empty():
		if arr.is_empty():
			break
		tile = available_tiles.pop_at(randi_range(0, available_tiles.size() - 1))

		if map_manager.map_dict.get(tile) != null:
			print("Tile occupied, skipping: ", tile)
			continue

		var chosen_res: UnitResource = arr.pop_front()
		new_unit = enemy_manager.create_unit_from_res(chosen_res)

		if new_unit:
			print("Spawned enemy unit: ", chosen_res)
		else:
			print("Failed to create enemy unit: ", chosen_res)
			continue

		# Add unit to manager and map
		enemy_manager.units.append(new_unit)
		map_manager.map_dict.set(tile, new_unit)
		new_unit.cur_pos = tile
		new_unit.global_position = map_manager.coords_to_glob(tile)
		
		if get_tree():
			await get_tree().process_frame
