extends Resource
class_name AIResource

@export var LOW_HEALTH_THRESHOLD:float = 0.1
@export var MID_HEALTH_THRESHOLD:float = 0.5
@export var THREATENING_DISTANCE:float = 10

@export_enum (
	"WHEN_THREATENED", # Ie, an enemy unit is within X distance
	"MID_HEALTH", # Retreat at a higher health threshold
	"LOW_HEALTH", # Retreat at the 'standard' health threshold
	"NEVER" # Never Retreat
) var when_to_retreat:int

@export_enum  (
	"TO_CLOSEST_FRIEND",
	"TO_FURTHEST_POINT_FROM_CLOSEST_ENEMY"
)var where_to_retreat_to:int

@export_enum  (
	"LAST_TO_DAMAGE", # Target the unit to last attack you; Otherwise, go for the closest
	"LOWEST_HEALTH", # Go for the unit with the least health
	"CLOSEST"
)var who_to_attack:int

@export_enum (
	"LOWEST_HEALTH",
	"CLOSEST"
)var who_to_support:int

@export_enum (
	"ATTACKER",
	"SUPPORTER"
)var type_of_unit:int


func return_info_as_string() -> String:
	var return_string = "[AI RESOURCE INFO]:"
	return_string += "\n\tLOW_HEALTH_THRESHOLD: " + str(LOW_HEALTH_THRESHOLD)
	return_string += "\n\tMID_HEALTH_THRESHOLD: " + str(MID_HEALTH_THRESHOLD)
	return_string += "\n\tTHREATENING_DISTANCE: " + str(THREATENING_DISTANCE) 
	return_string += "\n\twhen_to_retreat: " + ("WHEN_THREATENED" if when_to_retreat == 0 else "MID_HEALTH" if when_to_retreat == 1 else "LOW_HEALTH" if when_to_retreat == 2 else "NEVER")
	return_string += "\n\twhere_to_retreat_to: " + ("TO_CLOSEST_FRIEND" if where_to_retreat_to == 0 else "TO_FURTHEST_POINT_FROM_CLOSEST_ENEMY")
	return_string += "\n\twho_to_attack: " + ("LAST_TO_DAMAGE" if who_to_attack == 0 else "LOWEST_HEALTH" if who_to_attack == 1 else "CLOSEST")
	return_string += "\n\twho_to_support: " + ("LOWEST_HEALTH" if type_of_unit == 0 else "CLOSEST")
	return_string += "\n\ttype_of_unit: " + ("ATTACKER" if type_of_unit == 0 else "SUPPORTER")
	return return_string
