extends Node
class_name UnitManager

@export var attack_action: Attackaction

var pathfinder:Pathfinder
var primer:Object
var faction_dict:Dictionary[int, Faction] = {}
var unit_manager_holder:Dictionary[int, Array]

enum relation_types {
	HOSTILE,
	NEUTRAL,
	FRIENDLY	,
	UNKNOWN
}

func _init(given_primer:Object) -> void:
	pathfinder = Pathfinder.new(given_primer.get_terrain_tile_map())

func provide_factions() -> Dictionary[int, Faction]:
	return faction_dict

func add_faction(faction_id:int):
	faction_dict[faction_id] = Faction.new(faction_id, self)
	for faction_id_entry in faction_dict:
		if faction_id_entry != faction_id:
			var pulled_faction:Faction = faction_dict.get(faction_id_entry)
			var pulled_faction_relations:Array = pulled_faction.provide_relations()
			if (faction_id not in pulled_faction_relations[relation_types.HOSTILE]) and (faction_id not in pulled_faction_relations[relation_types.NEUTRAL] and (faction_id not in pulled_faction_relations[relation_types.FRIENDLY])):
				pulled_faction.add_new_relation(1, faction_id)

func get_enemies() -> Array: #checks for new enemies
	return get_tree().get_nodes_in_group("enemies")

func get_pc_units() -> Array: #checks for new pc-units
	return get_tree().get_nodes_in_group("PCunits")

func in_view(user: Unit, target: Entity) -> bool:
	var distance = Globals.get_3d_euclidean_distance(user.provide_coordinate(), target.provide_coordinate()) #checks distance of target
	if distance <= user.vision_dist and target.provide_coordinate() in user.provide_vision():
		return true
	return false

func remove_unit_from_game(provided_unit:Unit):
	var unit_faction:int = provided_unit._get_unit_type()
	for faction_id_entry in faction_dict:
		if faction_id_entry != unit_faction:
			faction_dict.get(faction_id_entry).remove_other_faction_unit(provided_unit)
	faction_dict.get(unit_faction).remove_unit(provided_unit)
	
func add_unit_to_game(faction_id:int, coordinate:Vector2i, info:Dictionary) -> Unit:
	var new_unit:Unit = null
	if faction_id not in faction_dict:
		add_faction(faction_id)
	if faction_id == 0:
		new_unit = Player_Unit.new(pathfinder, coordinate, info)
	else:
		new_unit = Enemy_Unit.new(pathfinder, coordinate, info)
	var faction_obj:Faction = faction_dict.get(faction_id)
	faction_obj.add_unit(new_unit)
	return new_unit
	
# Omniescent
func is_tile_occupied(provided_coordinate:Vector3i)->bool:
	for faction_entry in faction_dict:
		var faction_obj:Faction = faction_dict.get(faction_entry)
		var faction_units:Dictionary[Vector3i, Unit] = faction_obj.provide_faction_units()
		if provided_coordinate in faction_units:
			return true
	return false
	
# Omniescent
func is_tile_occupied_by_opposer(provided_faction:int, provided_coordinate:Vector3i)->bool:
	if provided_faction not in faction_dict: return false
	if not is_tile_occupied(provided_coordinate): return false
	var faction_obj:Faction = faction_dict.get(provided_faction)
	for hostile_faction_ids in faction_obj.provide_relations()[relation_types.HOSTILE]:
		var hostile_faction_units:Dictionary[Vector3i, Unit] = faction_dict.get(hostile_faction_ids).provide_faction_units()
		if provided_coordinate in hostile_faction_units:
			return true
	return false

func get_unit_on_tile(provided_coordinate:Vector3i)->Unit:
	for faction_id in faction_dict:
		var faction_obj:Faction = faction_dict.get(faction_id)
		var faction_units:Dictionary[Vector3i, Unit] = faction_obj.provide_faction_units()
		if provided_coordinate in faction_units:
			return faction_units.get(provided_coordinate)
	return null
