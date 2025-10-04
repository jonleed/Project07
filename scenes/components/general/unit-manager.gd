extends Node
class_name UnitManager

@export var attack_action: Attackaction

var pathfinder:Pathfinder
var primer:Object
var faction_dict:Dictionary[int, Faction] = {}
var unit_manager_holder:Dictionary[int, Array]
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
	faction_dict[Globals.PLAYER_FACTION_ID] = Player_Faction.new(Globals.PLAYER_FACTION_ID, self)
	faction_dict[Globals.TRAP_FACTION_ID] = Trap_Faction.new(Globals.TRAP_FACTION_ID, self)
	add_child(faction_dict.get(Globals.PLAYER_FACTION_ID))
	add_child(faction_dict.get(Globals.TRAP_FACTION_ID))
	game_loop()
	
func game_loop()->void:
	while not game_concluded:
		execute_turns()
		if exfiltration_complete_flag:
			game_concluded = true
			win_state = true
		elif len(faction_dict.get(Globals.PLAYER_FACTION_ID).provide_faction_units()) < 1:
			game_concluded = true
	
	if win_state:
		victory()
	else:
		gameover()

func gameover():
	emit_signal("Failure")
	
func victory():
	emit_signal("Survived")

# PURPOSE: Iterate through each faction and have them do their turns sequentially
func execute_turns():
	for faction_id_entry in faction_dict:
		var faction_obj:Faction = faction_dict.get(faction_id_entry)
		faction_obj.execute_turn()

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
		var unit_faction_obj:Faction = faction_dict.get(unit_cast.faction_id)
		provided_entity.arbitrary_move(twod_vect)
		unit_faction_obj.change_unit_position_ref(prior_coord, new_coordinate)		
	
	
# PURPOSE: Return a dictionary of faction id's keyed to the Faction object
func provide_factions() -> Dictionary[int, Faction]:
	return faction_dict

# PURPOSE: Add a new NPC_Faction
func add_npc_faction(faction_id:int, relationship_to_player:int):
	var new_faction:NPC_Faction =  NPC_Faction.new(faction_id, self)
	faction_dict[faction_id] = new_faction
	new_faction.faction_specific_setup(relationship_to_player)					

# PURPOSE: Provide an (Omniescent) array of Hostile NPC_Units
func get_enemies() -> Array: #checks for new enemies
	return get_tree().get_nodes_in_group("enemies")

# PURPOSE: Provide an (Omniescent) array of Player_Units
func get_pc_units() -> Array: #checks for new pc-units
	return get_tree().get_nodes_in_group("PCunits")
	
# PURPOSE: Provide an (Omniescent) array of Traps
func get_traps() -> Array:
	return get_tree().get_nodes_in_group("Traps")
	
# PURPOSE: Provide an (Omniescent) array of NPC_Units that view the Player_Faction has neutral
func get_neutral_units() -> Array:
	return get_tree().get_nodes_in_group("neutral")
	
# PURPOSE: Provide an (Omniescent) array of NPC_Units that view the Player_Faction has friendly
func get_friendly_units() -> Array:
	return get_tree().get_nodes_in_group("friendly")

func in_view(user: Unit, target: Entity) -> bool:
	var distance = Globals.get_3d_euclidean_distance(user.provide_coordinate(), target.provide_coordinate()) #checks distance of target
	if distance <= user.vision_dist and target.provide_coordinate() in user.provide_vision():
		return true
	return false

# PURPOSE: Call this to delete a unit entirely from the game
func remove_unit_from_game(provided_unit:Unit):
	var unit_faction:int = provided_unit.get_faction_id()
	for faction_id_entry in faction_dict:
		if faction_id_entry != unit_faction:
			faction_dict.get(faction_id_entry).remove_other_faction_unit(provided_unit)
	faction_dict.get(unit_faction).remove_unit(provided_unit)
	
# PURPOSE: Call this to add a unit to the game
# ADDENUMN: This only handles Units/Traps
func add_unit_to_game(faction_id:int, coordinate:Vector2i, info:Dictionary) -> Entity:
	var new_unit:Entity = null
	if faction_id not in faction_dict:
		# If we add a new faction and not given info on it, just assume it's hostile
		add_npc_faction(faction_id, UnitManager.relation_types.HOSTILE)
	if faction_id == Globals.PLAYER_FACTION_ID:
		new_unit = Player_Unit.new(pathfinder, coordinate, self, info, Globals.PLAYER_FACTION_ID)
		new_unit.connect("ATK-"+str(new_unit.provide_entity_id()), Callable(new_unit, "afflicted_by_attack"))
		new_unit.connect("HEL-"+str(new_unit.provide_entity_id()), Callable(new_unit, "health_calc"))
		add_to_group("PCunits")
	elif faction_id == Globals.TRAP_FACTION_ID:
		new_unit = Trap.new(pathfinder, coordinate, self, info, Globals.TRAP_FACTION_ID)
		add_to_group("Traps")
	else:
		new_unit = NPC_Unit.new(pathfinder, coordinate, self, info, faction_id)
		var faction_relation = faction_dict.get(faction_id).provide_relation_type()
		if faction_relation == UnitManager.relation_types.HOSTILE:
			add_to_group("enemies")
		elif faction_relation == UnitManager.relation_types.NEUTRAL:
			add_to_group("neutral")
		elif faction_relation == UnitManager.relation_types.FRIENDLY:
			add_to_group("friendly")
	var faction_obj:Faction = faction_dict.get(faction_id)
	faction_obj.add_unit(new_unit)
	return new_unit
	
# PURPOSE: If a unit is on that coordinate, return true; This is Omniescent
func is_tile_occupied(provided_coordinate:Vector3i)->bool:
	for faction_entry in faction_dict:
		var faction_obj:Faction = faction_dict.get(faction_entry)
		var faction_units:Dictionary[Vector3i, Entity] = faction_obj.provide_faction_units()
		if provided_coordinate in faction_units:
			return true
	return false
	
# PURPOSE: Return true if a trap is present on the tile; This is Omniescent
func is_trap_present(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in faction_dict.get(Globals.TRAP_FACTION_ID).provide_faction_units()
	
# Omniescent
#func is_tile_occupied_by_opposer(provided_faction:int, provided_coordinate:Vector3i)->bool:
#	if provided_faction not in faction_dict: return false
#	if not is_tile_occupied(provided_coordinate): return false
#	var faction_obj:Faction = faction_dict.get(provided_faction)
#	for hostile_faction_ids in faction_obj.provide_relations()[UnitManager.relation_types.HOSTILE]:
#		var hostile_faction_units:Dictionary[Vector3i, Unit] = faction_dict.get(hostile_faction_ids).provide_faction_units()
#		if provided_coordinate in hostile_faction_units:
#			return true
#	return false

# PURPOSE: Return the unit on a given coordinate
func get_unit_on_tile(provided_coordinate:Vector3i)->Entity:
	for faction_id in faction_dict:
		var faction_obj:Faction = faction_dict.get(faction_id)
		var faction_units:Dictionary[Vector3i, Entity] = faction_obj.provide_faction_units()
		if provided_coordinate in faction_units:
			return faction_units.get(provided_coordinate)
	return null
