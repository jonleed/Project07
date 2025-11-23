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
