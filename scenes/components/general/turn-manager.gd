extends Node
class_name TurnManager

@export var attack_action: Attackaction

var pathfinder:Pathfinder
var primer:Object
var manager_dict:Dictionary[int, Manager] = {}
var turn_manager_holder:Dictionary[int, Array]
var game_concluded:bool = false
var win_state:bool = false
var exfiltration_complete_flag:bool = false

enum relation_types {
	HOSTILE,
	NEUTRAL,
	FRIENDLY	,
	UNKNOWN
}

# ADDENDUMN: given_primer is meant to be whatever the root for Phase2/Phase3 is
func _init(given_primer:Object) -> void:
	pathfinder = Pathfinder.new(given_primer.get_terrain_tile_map())
	manager_dict[Globals.PLAYER_MANAGER_ID] = Player_Manager.new(Globals.PLAYER_MANAGER_ID, self)
	manager_dict[Globals.TRAP_MANAGER_ID] = Trap_Manager.new(Globals.TRAP_MANAGER_ID, self)
	add_child(manager_dict.get(Globals.PLAYER_MANAGER_ID))
	add_child(manager_dict.get(Globals.TRAP_MANAGER_ID))
	game_loop()
	
func game_loop()->void:
	while not game_concluded:
		execute_turns()
		if exfiltration_complete_flag:
			game_concluded = true
			win_state = true
		elif len(manager_dict.get(Globals.PLAYER_MANAGER_ID).provide_manager_units()) < 1:
			game_concluded = true
	
	if win_state:
		victory()
	else:
		gameover()

func gameover():
	emit_signal("Failure")
	
func victory():
	emit_signal("Survived")

# PURPOSE: Iterate through each manager and have them do their turns sequentially
func execute_turns():
	for manager_id_entry in manager_dict:
		var manager_obj:Manager = manager_dict.get(manager_id_entry)
		manager_obj.execute_turn()

# PURPOSE: Given an entity and a coordinate, move the entity to that coordinate
func move_entity(provided_entity:Entity, new_coordinate):
	var twod_vect = null
	if new_coordinate is Vector3i or new_coordinate is Vector3:
		twod_vect = provided_entity.pathfinder.downgrade_vector(new_coordinate)
	else:
		twod_vect = new_coordinate
	var ent_type = provided_entity.provide_entity_type()
	if ent_type == Entity.entity_types.DYNAMIC:
		provided_entity.arbitrary_move(twod_vect)
	elif ent_type == Entity.entity_types.PLAYER_UNIT or ent_type == Entity.entity_types.NPC_UNIT:
		var unit_cast:Unit = provided_entity
		var prior_coord = unit_cast.provide_coordinate()
		var turn_manager_obj:Manager = manager_dict.get(unit_cast.manager_id)
		provided_entity.arbitrary_move(twod_vect)
		turn_manager_obj.change_unit_position_ref(prior_coord, new_coordinate)		
	
	
# PURPOSE: Return a dictionary of manager id's keyed to the Manager object
func provide_managers() -> Dictionary[int, Manager]:
	return manager_dict

# PURPOSE: Add a new NPC_Manager
func add_npc_manager(manager_id:int, relationship_to_player:int):
	var new_manager:NPC_Manager =  NPC_Manager.new(manager_id, self)
	manager_dict[manager_id] = new_manager
	new_manager.manager_specific_setup(relationship_to_player)					

# PURPOSE: Provide an (Omniescent) array of Hostile NPC_Units
func get_enemies() -> Array: #checks for new enemies
	return get_tree().get_nodes_in_group("enemies")

# PURPOSE: Provide an (Omniescent) array of Player_Units
func get_pc_units() -> Array: #checks for new pc-units
	return get_tree().get_nodes_in_group("PCunits")
	
# PURPOSE: Provide an (Omniescent) array of Traps
func get_traps() -> Array:
	return get_tree().get_nodes_in_group("Traps")
	
# PURPOSE: Provide an (Omniescent) array of NPC_Units that view the Player_Manager has neutral
func get_neutral_units() -> Array:
	return get_tree().get_nodes_in_group("neutral")
	
# PURPOSE: Provide an (Omniescent) array of NPC_Units that view the Player_Manager has friendly
func get_friendly_units() -> Array:
	return get_tree().get_nodes_in_group("friendly")

func in_view(user: Unit, target: Entity) -> bool:
	var distance = Globals.get_3d_euclidean_distance(user.provide_coordinate(), target.provide_coordinate()) #checks distance of target
	if distance <= user.vision_dist and target.provide_coordinate() in user.provide_vision():
		return true
	return false

# PURPOSE: Call this to delete a unit entirely from the game
func remove_unit_from_game(provided_unit:Unit):
	var turn_manager:int = provided_unit.get_manager_id()
	for manager_id_entry in manager_dict:
		if manager_id_entry != turn_manager:
			manager_dict.get(manager_id_entry).remove_other_manager_unit(provided_unit)
	manager_dict.get(turn_manager).remove_unit(provided_unit)
	
# PURPOSE: Call this to add a unit to the game
# ADDENUMN: This only handles Units/Traps
func add_unit_to_game(manager_id:int, coordinate:Vector2i, info:Dictionary) -> Entity:
	var new_unit:Entity = null
	if manager_id not in manager_dict:
		# If we add a new manager and not given info on it, just assume it's hostile
		add_npc_manager(manager_id, TurnManager.relation_types.HOSTILE)
	if manager_id == Globals.PLAYER_MANAGER_ID:
		new_unit = Player_Unit.new(pathfinder, coordinate, self, info, Globals.PLAYER_MANAGER_ID)
		new_unit.connect("ATK-"+str(new_unit.provide_entity_id()), Callable(new_unit, "afflicted_by_attack"))
		new_unit.connect("HEL-"+str(new_unit.provide_entity_id()), Callable(new_unit, "health_calc"))
		add_to_group("PCunits")
	elif manager_id == Globals.TRAP_MANAGER_ID:
		new_unit = Trap.new(pathfinder, coordinate, self, info, Globals.TRAP_MANAGER_ID)
		add_to_group("Traps")
	else:
		new_unit = NPC_Unit.new(pathfinder, coordinate, self, info, manager_id)
		var manager_relation = manager_dict.get(manager_id).provide_relation_type()
		if manager_relation == TurnManager.relation_types.HOSTILE:
			add_to_group("enemies")
		elif manager_relation == TurnManager.relation_types.NEUTRAL:
			add_to_group("neutral")
		elif manager_relation == TurnManager.relation_types.FRIENDLY:
			add_to_group("friendly")
	var manager_obj:Manager = manager_dict.get(manager_id)
	manager_obj.add_unit(new_unit)
	return new_unit
	
# PURPOSE: If a unit is on that coordinate, return true; This is Omniescent
func is_tile_occupied(provided_coordinate:Vector3i)->bool:
	for manager_entry in manager_dict:
		var manager_obj:Manager = manager_dict.get(manager_entry)
		var manager_units:Dictionary[Vector3i, Entity] = manager_obj.provide_manager_units()
		if provided_coordinate in manager_units:
			return true
	return false
	
# PURPOSE: Return true if a trap is present on the tile; This is Omniescent
func is_trap_present(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in manager_dict.get(Globals.TRAP_MANAGER_ID).provide_manager_units()
	
# Omniescent
#func is_tile_occupied_by_opposer(provided_manager:int, provided_coordinate:Vector3i)->bool:
#	if provided_manager not in manager_dict: return false
#	if not is_tile_occupied(provided_coordinate): return false
#	var manager_obj:Manager = manager_dict.get(provided_manager)
#	for hostile_manager_ids in manager_obj.provide_relations()[TurnManager.relation_types.HOSTILE]:
#		var hostile_manager_units:Dictionary[Vector3i, Unit] = manager_dict.get(hostile_manager_ids).provide_manager_units()
#		if provided_coordinate in hostile_manager_units:
#			return true
#	return false

# PURPOSE: Return the unit on a given coordinate
func get_unit_on_tile(provided_coordinate:Vector3i)->Entity:
	for manager_id in manager_dict:
		var manager_obj:Manager = manager_dict.get(manager_id)
		var manager_units:Dictionary[Vector3i, Entity] = manager_obj.provide_manager_units()
		if provided_coordinate in manager_units:
			return manager_units.get(provided_coordinate)
	return null
