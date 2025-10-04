extends Entity
class_name Unit

#export variables
@export_category("Current Unit Values")
@export var move_dist : int = 5
@export var health : int = 10
@export var current_mana : int = 5
@export var actions_left : int = 1

@export_subgroup("Base Unit Abilities")
@export var max_move_dist : int = 5
@export var max_health:int = 10
@export var action_max : int = 1
@export var vision_dist : int = 15
@export var max_mana : int = 5
@export var unit_volume : int = 20

enum action_type {
	NEUTRAL,
	BENIGN,
	MALIGNANT
}

#local variables
var has_moved:bool = false
var action_count : int
var allowed_actions:Array[Action]
var unit_manager_ref:UnitManager
var visible_tiles:Array = [clean_coordinate]
var information_heard:Dictionary[Vector3i, int] = {}
var faction_id:int

func unit_setup(provided_info:Dictionary, provided_faction_id:int, given_unit_manager:UnitManager) -> void:
	unit_manager_ref = given_unit_manager
	faction_id = provided_faction_id
	allowed_actions = []
	visible_tiles = [clean_coordinate]
	set_entity_type()
	# Parse info from provided_info and assign actions/gear/other stuff
	update_vision()
	
func _ready() -> void:
	pass
	
func execute_turn()->void:
	pass
	
# Overrided by Inherited classes
func set_entity_type()->void:
	# Default to NPC
	entity_type = Entity.entity_types.NPC_UNIT
	
func add_action(provided_action:Action):
	allowed_actions.append(provided_action)
	
func remove_action(action_name):
	var tmp = allowed_actions.find(action_name)
	if tmp != -1:
		allowed_actions.remove_at(allowed_actions.find(action_name))
	
func move_to_location(target:Vector3i):
	var pt_id = move_path(target)[0]
	var identifier_map = pathfinder._provide_inverted_identifier_map()
	arbitrary_move(pathfinder.downgrade_vector(identifier_map.get(pt_id)))
	update_vision()
	
func get_allowed_tiles() -> Array:
	return Globals.get_bfs_range(Vector2i(coordinate.x, coordinate.y), move_dist)
	
func move_path(target:Vector3i) -> Array:
	return pathfinder._return_path(coordinate, target)

func get_valid_mana(mana_needed) -> bool:
	if mana_needed > current_mana:
		return true
	return false

func adjust_health(delta:int) -> void:
	health += delta
	if delta < 0:
		send_data(action_type.MALIGNANT)
	health = max(0, min(health, max_health))
	if health <= 0:
		destroy_unit()
		
func health_calc(provided_action:Healaction) -> void:
	adjust_health(provided_action.heal)
		
func afflicted_by_attack(provided_action:Attackaction) -> void:
	adjust_health(-1 * provided_action.damage.dmg)
	
func adjust_mana(delta:int) -> void:
	current_mana += delta
	current_mana = max(0, min(current_mana, max_mana))

func _set_max_health(provided_maximum:int) -> void:
	max_health = max(1, provided_maximum)

func _set_vision_distance(provided_vision:int) -> void:
	vision_dist = max(1, provided_vision)
	
func _set_action_max(provided_maximum:int) -> void:
	action_max = max(0, provided_maximum)

func _set_mana_max(provided_maximum:int) -> void:
	max_mana = max(0, provided_maximum)

func destroy_unit() -> void:
	remove_from_group("PCunits")
	remove_from_group("enemies")
	remove_from_group("friendlies")
	remove_from_group("neutrals")
	queue_free()
	
#this should be probably managed by damage function but i wanted something for the trap
func isHurt(amount: int):
	adjust_health(amount * -1);
	print("owie");
	
func get_faction_id()->int:
	return faction_id
	
func provide_vision()->Array:
	return visible_tiles
	
func update_vision()->void:
	visible_tiles = Globals.get_bfs_range(clean_coordinate, vision_dist)
	unit_manager_ref.provide_factions().get(faction_id).assemble_faction_vision()
	#update_tiles_visible_to_team(faction_id)
	
func parse_atk_signal()->void:
	pass
	
func send_data(provided_action_type:int) -> void:
	if provided_action_type not in action_type:
		return
	var heard_tiles:Array = Globals.get_bfs_range(clean_coordinate, unit_volume)
	for tile in heard_tiles:
		var unit_ref:Unit = unit_manager_ref.get_unit_on_tile(tile)
		if unit_ref != null:
			unit_ref.recieve_information(tile, provided_action_type)
			
func recieve_information(provided_coordinate:Vector3i, action_heard:int):
	information_heard[provided_coordinate] = action_heard
		
func is_turn_unfinished()->bool:
	return actions_left > 0	
