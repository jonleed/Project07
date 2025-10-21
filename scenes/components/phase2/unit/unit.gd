extends Entity
class_name Unit

@export_subgroup("Unit Action")
@export var action_array:Array[Action]
#to check if has acted, check if action_count<action_max
@export var action_max:int = 1
var action_count:int = action_max

@export_subgroup("Unit Movement")
@export var move_max:int = 5
var move_count:int = move_max

@export_subgroup("Unit Cosmetics")
@export var unit_name:String = "Joe"
@export var icon_sprite:Texture2D = null

@export_subgroup("Resource")
##this variable isnt required, only useful if the unit spawns on the first
@export var u_res:UnitResource = null

var cached_parent:Unit_Manager

# Checks if unit has actions remaining
func can_act() -> bool:
	return action_count > 1

# Checks if unit has moves remaining
func can_move() -> bool:
	return move_count > 1

func load_unit_res(unit_res:UnitResource = null):
	if not unit_res:
		return
	#unit variables
	action_array = unit_res.action_array.duplicate(true)
	action_max = unit_res.action_max
	action_count = action_max
	move_max = unit_res.move_max
	move_count = move_max
	icon_sprite = unit_res.icon_sprite
	unit_name = unit_res.unit_name
	#entity variables
	base_health = unit_res.base_health
	health = base_health
	immortal = unit_res.immortal
	entity_shape = unit_res.entity_shape
	anim_frames = unit_res.anim_frames
	anim_sprite.sprite_frames = anim_frames
	if anim_frames.get_animation_names().has("Idle"):
		anim_sprite.animation = "Idle"
	
func get_move_actions() -> Array[Moveaction]:
	var move_action_arr:Array[Moveaction] = []
	for action in action_array:
		if action is Moveaction:
			move_action_arr.append(action)
	return move_action_arr
	
func get_attack_actions() -> Array[Attackaction]:
	var attack_action_arr:Array[Attackaction] = []
	for action in action_array:
		if action is Attackaction:
			attack_action_arr.append(action)
	return attack_action_arr
	
func get_restorative_actions() -> Array[Healaction]:
	var restorative_action_arr:Array[Healaction] = []
	for action in action_array:
		if action is Healaction:
			restorative_action_arr.append(action)
	return restorative_action_arr
	
## Move actions should set go_final to true; ATK actions should set go_final to false (as the final point is the tile the enemy unit is on)
## Do not call manually- call the UnitManager's move_unit_via_path() in order to also adjust map_manager
func move_down_path(path_arr:PackedVector2Array, go_final:bool):
	var pathfinder:Pathfinder = get_parent().get_pathfinder()
	for index in range(1, len(path_arr)):
		if move_count < 1:
			break
		if index != len(path_arr) - 1 or (go_final):
			if path_arr[index] == Vector2(-1234, -1234):
				break
			else:
				move_count -= 1
				cur_pos = path_arr[index]
				# Move incrementally, not all at once, to give traps a chance to trigger for when the body is entered.
				# Ideally we'd be emitting a signal that the traps can monitor


func get_friendly_factions() -> Array[String]:
	var faction_name_ref:String = cached_parent.faction_name
	if faction_name_ref == "Friendly" or faction_name_ref == "Player Unit":
		return ["Friendly", "Player Unit"]
	elif faction_name_ref == "Traps":
		return ["Traps"]
	elif faction_name_ref == "Enemy":
		return ["Enemy"]
	return ["Enemy"]

func get_enemy_unit_factions() -> Array[String]:	
	var faction_name_ref:String = cached_parent.faction_name
	if faction_name_ref == "Friendly" or faction_name_ref == "Player Unit":
		return ["Enemy"]
	elif faction_name_ref == "Traps":
		return ["Friendly", "Player Unit", "Enemy"]
	elif faction_name_ref == "Enemy":
		return ["Player Unit", "Friendly"]
	return ["Friendly", "Player Unit"]

func get_multihit_targets(given_action:Action, focus:Entity, include_friendly:bool, include_hostile:bool, coordinate:Vector2i=cur_pos) -> Array[Entity]:
	var units_to_affect:Array[Entity] = [focus]
	if given_action.multihit_pattern == null:
		return units_to_affect
	if include_friendly:
		for faction_name_ref in get_friendly_factions():
			var faction_units = get_tree().get_nodes_in_group(faction_name_ref)
			for unit in faction_units:
				if unit != focus and Vector2(unit.cur_pos) in given_action.multihit_pattern.calculate_affected_tiles_from_center(coordinate):
					units_to_affect.append(unit)
	if include_hostile:
		for faction_name_ref in get_enemy_unit_factions():
			var faction_units = get_tree().get_nodes_in_group(faction_name_ref)
			for unit in faction_units:
				if unit != focus and Vector2(unit.cur_pos) in given_action.multihit_pattern.calculate_affected_tiles_from_center(coordinate):
					units_to_affect.append(unit)
	return units_to_affect
	
## For Heal/Attack Actions
func use_action(given_action:Action, focus:Entity) -> void:
	var include_F:bool = false
	var include_H:bool = false
	if given_action is Healaction:
		include_F = true
	elif given_action is Attackaction:
		include_H = true
	var units_to_affect:Array[Entity] = get_multihit_targets(given_action, focus, include_F, include_H)
	cached_parent.action_decoder.decode_action(given_action, units_to_affect)
	
	
func _ready() -> void:
	# This is overriden by ally_unit.gd
	add_to_group("Base Faction")
