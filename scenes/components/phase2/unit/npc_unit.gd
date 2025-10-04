extends Unit
class_name NPC_Unit

enum alert_level {
	BLUE, # Idling
	GREEN, # Situation normal
	YELLOW, # Warned by ally of potential hostilities
	ORANGE, # Recently saw an enemy
	RED # See an enemy
}

enum enemy_action_choices {
	NOTHING,
	PATROL,
	SEARCH,
	ATTACK,
	REGROUP	
}

var alertness = alert_level.GREEN
var visible_hostiles:Dictionary[Vector3i, Unit] = {}
var time_since_last_enemy_seen = 0

func set_entity_type()->void:
	entity_type = Entity.entity_types.NPC_UNIT
	
func execute_turn()->void:
	examine_information()
	examine_surroundings()	
	if alertness == alert_level.BLUE:
		# just stand around uselessly
		pass
	elif alertness == alert_level.GREEN:
		# patrol near objective/assigned area
		pass
	elif alertness == alert_level.YELLOW:
		# investigate sound
		pass
	elif alertness == alert_level.ORANGE:
		# search for enemy
		pass
	elif alertness == alert_level.RED:
		if health < max_health / 3.0 and len(visible_hostiles) > 2:
			action_retreat()
		pass
	
func action_retreat() -> void:
	pass
	
func examine_information() -> void:
	for tile in information_heard:
		var dict_value:int = information_heard.get(tile)
		if dict_value == action_type.MALIGNANT and alertness == alert_level.GREEN:
			alertness = alert_level.YELLOW
			break
	
func examine_surroundings() -> void:
	# NOTE: This is an array with two dictionarys
	visible_hostiles = unit_manager_ref.provide_factions().get(faction_id).provide_hostile_units()
	var active_watch = false
	for hostile_unit_coord in visible_hostiles:
		if hostile_unit_coord in visible_tiles:
			alertness = alert_level.RED
			active_watch = true
			time_since_last_enemy_seen = 0
			break 
	if not active_watch:
		time_since_last_enemy_seen += 1
		if alertness == alert_level.RED:
			alertness = alert_level.ORANGE
		elif time_since_last_enemy_seen > 7:
			alertness = alert_level.GREEN
		elif time_since_last_enemy_seen > 3:
			alertness = alert_level.YELLOW
	
func provide_entity_type()->int:
	return entity_type
