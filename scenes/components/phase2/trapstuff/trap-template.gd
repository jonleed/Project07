#we need to look into trap placement
#tile gen
extends Entity
class_name Trap

@onready var map_manager = get_tree().get_first_node_in_group("MapManager")
@export var action_array:Array[Action]
var action_count:int = action_max
@export var action_max:int = 1
var action_decoder: ActionDecoder


@export_subgroup("Base Trap Values")
@export var vision_dist: int = 5

signal activation(trap: Trap)
signal destroyed(trap: Trap)
signal dismantled(trap: Trap)

var has_activated: bool = false
var is_functional: bool = true

func _ready() -> void:
	ready_entity()
	var tilemap: TileMapLayer = get_parent()
	connect("health_changed", Callable(self, "_on_health_changed"))
	var coord: Vector2i = tilemap.local_to_map(global_position)
	map_manager.astar.set_point_solid(coord, false)
	set_meta("tile_coord", coord)

func _assign_action_decoder() -> void:
	if action_decoder == null:
		var manager = get_tree().get_first_node_in_group("TrapManager")
		print("[SpikeTrap] Found TrapManager:", manager)
		if manager:
			action_decoder = manager.action_decoder
			print("[SpikeTrap] Assigned decoder:", action_decoder)


func _on_health_changed(changed_node: Entity) -> void:
	if health <= 0 and not immortal:
		on_destroy()

func dismantle_trap() -> void:
	if not is_functional:
		return
	is_functional = false
	print(name, "was dismantled.")
	emit_signal("dismantled", self)

func on_destroy() -> void:
	if not is_functional:
		return
	is_functional = false
	print(name, "was destroyed.")
	emit_signal("destroyed", self)
	queue_free()

func get_trap_status() -> bool:
	emit_signal("activation", self)
	return has_activated

func on_activate(_body: Node = null) -> void:
	pass  
