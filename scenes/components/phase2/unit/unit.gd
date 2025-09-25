extends Entity
class_name Unit

#export variables
@export_subgroup("Base Unit Abilities")
@export var move_dist : int = 5
@export var max_health:int = 10
@export var health : int = 10
@export var action_max : int = 1
@export var vision_dist : int = 15
@export var current_mana : int = 5
@export var max_mana : int = 5

#local variables
var has_moved:bool = false
var action_count : int

var allowed_actions:Array[Action]

func _init(pathfinder_ref:Pathfinder, spawn_pos:Vector2i) -> void:
	pathfinder = pathfinder_ref
	var tmp_ref = pathfinder._provide_tile_map_ref()
	var tmp_surf_map = tmp_ref._provide_surface_map()
	if spawn_pos in tmp_surf_map:
		coordinate = Vector3i(spawn_pos.x, spawn_pos.y, tmp_surf_map.get(spawn_pos))
		clean_coordinate = spawn_pos
	else:
		var tmp_arr = tmp_surf_map.keys()
		coordinate = Vector3i(tmp_arr[0].x, tmp_arr[0].y, tmp_surf_map.get(tmp_arr[0]))
		clean_coordinate = Vector2i(tmp_arr[0].x, tmp_arr[0].y)
	allowed_actions = []
	
func _ready() -> void:
	pass
	
func add_action(provided_action:Action):
	allowed_actions.append(Action)
	
func remove_action(action_name):
	var tmp = allowed_actions.find(action_name)
	if tmp != -1:
		allowed_actions.remove_at(allowed_actions.find(action_name))
	
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
	health = max(0, min(health, max_health))
	if health <= 0:
		destroy_unit()

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
	pass
	
#this should be probably managed by damage function but i wanted something for the trap
func isHurt(amount: int):
	adjust_health(amount * -1);
	print("owie");
