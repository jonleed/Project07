extends Node
class_name UnitManager

@export var attack_action: Attackaction

enum unit_types {
	ENEMY,
	FRIENDLY,
	PLAYER
}

var pathfinder:Pathfinder
var primer:Object
var unit_manager_holder:Dictionary[int, Array]
var unit_manager_prime:Dictionary[Vector3i, Unit]
var faction_vision_manager:Dictionary[int, Array]
var faction_visible_hostiles:Dictionary[int, Array]
func _init(given_primer:Object) -> void:
	pathfinder = Pathfinder.new(given_primer.get_terrain_tile_map())
	for entry in unit_types:
		unit_manager_holder[entry] = [{}, {}]
		faction_vision_manager[entry] = []
		faction_visible_hostiles[entry] = [{}, {}]

func get_enemies() -> Array: #checks for new enemies
	return get_tree().get_nodes_in_group("enemies")

func get_pc_units() -> Array: #checks for new pc-units
	return get_tree().get_nodes_in_group("PCunits")

func in_view(user: Node, target: Node) -> bool:
	var distance = user.global_position.distance_to(target.global_position) #checks distance of target
	return distance <= user.vision_dist

func destroy_unit(provided_unit:Unit):
	var provided_unit_type:int = provided_unit._get_unit_type()
	var provided_unit_id:int = provided_unit.provide_entity_id()
	var provided_unit_coordinate:Vector3i = provided_unit.provide_coordinate()
	unit_manager_holder[provided_unit_type][0].erase(provided_unit_id)
	unit_manager_holder[provided_unit_type][0].erase(provided_unit_coordinate)
	update_tiles_visible_to_team(provided_unit_type)
	if provided_unit_type == unit_types.FRIENDLY or provided_unit_type == unit_types.PLAYER:
		faction_visible_hostiles[unit_types.ENEMY][0].erase(provided_unit_id)
		faction_visible_hostiles[unit_types.ENEMY][1].erase(provided_unit_coordinate)
	else:
		faction_visible_hostiles[unit_types.FRIENDLY][0].erase(provided_unit_id)
		faction_visible_hostiles[unit_types.FRIENDLY][1].erase(provided_unit_coordinate)
		faction_visible_hostiles[unit_types.PLAYER][0].erase(provided_unit_id)
		faction_visible_hostiles[unit_types.PLAYER][1].erase(provided_unit_coordinate)
	unit_manager_prime.erase(provided_unit_coordinate)
	
func _create_unit(provided_unit_type:int, coordinate:Vector2i, info:Dictionary) -> Unit:
	var new_unit:Unit = null
	match provided_unit_type:
		unit_types.ENEMY:
			new_unit = Enemy_Unit.new(pathfinder, coordinate, info)
		unit_types.FRIENDLY:
			new_unit = Friendly_Unit.new(pathfinder, coordinate, info)
		unit_types.PLAYER:
			new_unit = Player_Unit.new(pathfinder, coordinate, info)	
	unit_manager_holder[provided_unit_type][0][new_unit.provide_entity_id()] = new_unit
	unit_manager_holder[provided_unit_type][1][new_unit.provide_coordinate()] = new_unit.provide_entity_id()
	unit_manager_prime[new_unit.provide_coordinate()] = new_unit
	update_tiles_visible_to_team(provided_unit_type)
	return new_unit
	
func get_units_by_id(provided_unit_type:int)->Dictionary:
	if provided_unit_type not in unit_types:
		return {}
	return unit_manager_holder.get(provided_unit_type)[0]

func get_units_by_coord(provided_unit_type:int)->Dictionary:
	if provided_unit_type not in unit_types:
		return {}
	return unit_manager_holder.get(provided_unit_type)[1]
	
func get_hostiles_visible_to_team(provided_unit_type:int)->Array[Dictionary]:
	if provided_unit_type not in unit_types:
		return [{}]
	return faction_visible_hostiles.get(provided_unit_type)
	
func is_tile_occupied(provided_coordinate:Vector3i)->bool:
	for entry in unit_types:
		if provided_coordinate in unit_manager_holder.get(entry)[0]:
			return true
	return false
	
func is_tile_occupied_by_opposer(provided_unit_type:int, provided_coordinate:Vector3i)->bool:
	if provided_unit_type not in unit_types:
		return is_tile_occupied(provided_coordinate)
	elif provided_unit_type == unit_types.ENEMY:
		if provided_coordinate in unit_manager_holder.get(unit_types.PLAYER)[0]:
			return true
		elif provided_coordinate in unit_manager_holder.get(unit_types.FRIENDLY)[0]:
			return true
		return false
	elif provided_unit_type == unit_types.FRIENDLY or provided_unit_type == unit_types.PLAYER:
		if provided_coordinate in unit_manager_holder.get(unit_types.ENEMY)[0]:
			return true
		return false
	return false

func update_tiles_visible_to_team(provided_unit_type:int)->void:
	var visible_tiles:Dictionary[Vector3i, bool] = {}
	if provided_unit_type not in unit_types:
		return
	if provided_unit_type == unit_types.ENEMY:
		for unit:Unit in unit_manager_holder.get(unit_types.ENEMY)[0]:
			var new_tiles = unit.provide_vision()
			for tile in new_tiles:
				if tile not in visible_tiles:
					visible_tiles[tile] = true
		faction_vision_manager[unit_types.ENEMY] = visible_tiles.keys()
	elif provided_unit_type == unit_types.FRIENDLY or provided_unit_type == unit_types.PLAYER:
		for unit:Unit in unit_manager_holder.get(unit_types.FRIENDLY)[0]:
			var new_tiles:Array = unit.provide_vision()
			for tile in new_tiles:
				if tile not in visible_tiles:
					visible_tiles[tile] = true
		for unit:Unit in unit_manager_holder.get(unit_types.PLAYER)[0]:
			var new_tiles:Array = unit.provide_vision()
			for tile in new_tiles:
				if tile not in visible_tiles:
					visible_tiles[tile] = true
		var tmp_keys:Array = visible_tiles.keys()
		faction_vision_manager[unit_types.FRIENDLY] = tmp_keys
		faction_vision_manager[unit_types.PLAYER] = tmp_keys
	update_visible_hostiles(provided_unit_type)

func get_tiles_visible_to_team(provided_unit_type:int)->Array:
	if provided_unit_type not in unit_types:
		return []
	else:
		return faction_vision_manager[provided_unit_type]

func is_tile_visible_to_team(provided_unit_type:int, provided_tile:Vector3i)->bool:
	if provided_unit_type not in unit_types: return false
	else:
		return provided_tile in faction_vision_manager.get(provided_unit_type)

func update_visible_hostiles(provided_unit_type:int)->void:
	if provided_unit_type not in unit_types:
		return
	if provided_unit_type == unit_types.ENEMY:
		var temp_dictionary:Array = [{}, {}]
		for tile in faction_vision_manager.get(provided_unit_type):
			if is_tile_visible_to_team(provided_unit_type, tile) and is_tile_occupied_by_opposer(provided_unit_type, tile):	
				var hostile_id = -1
				var hostile_unit:Unit = null
				if tile in faction_vision_manager.get(unit_types.FRIENDLY)[1]:
					hostile_id = faction_vision_manager.get(unit_types.FRIENDLY)[1]
					hostile_unit = faction_vision_manager.get(unit_types.FRIENDLY)[0].get(hostile_id)
				elif tile in faction_vision_manager.get(unit_types.PLAYER)[1]:
					hostile_id = faction_vision_manager.get(unit_types.PLAYER)[1]
					hostile_unit = faction_vision_manager.get(unit_types.FRIENDLY)[0].get(hostile_id)
				temp_dictionary[0][hostile_id] = hostile_unit
				temp_dictionary[1][tile] = hostile_id
		faction_visible_hostiles[provided_unit_type] = temp_dictionary
	elif provided_unit_type == unit_types.FRIENDLY or provided_unit_type == unit_types.PLAYER:
		var temp_dictionary:Array = [{}, {}]
		for tile in faction_vision_manager.get(provided_unit_type):
			if is_tile_visible_to_team(provided_unit_type, tile) and is_tile_occupied_by_opposer(provided_unit_type, tile):	
				if tile in faction_vision_manager.get(unit_types.ENEMY)[1]:
					var hostile_id:int = faction_vision_manager.get(unit_types.FRIENDLY)[1]
					var hostile_unit:Unit = faction_vision_manager.get(unit_types.FRIENDLY)[0].get(hostile_id)
					temp_dictionary[0][hostile_id] = hostile_unit
					temp_dictionary[1][tile] = hostile_id
		# It's fine to use a shallow copy because Friendly/Player share vision
		faction_visible_hostiles[unit_types.FRIENDLY] = temp_dictionary
		faction_visible_hostiles[unit_types.PLAYER] = temp_dictionary

func get_unit_on_tile(provided_tile:Vector3i)->Unit:
	return unit_manager_prime.get(provided_tile)
