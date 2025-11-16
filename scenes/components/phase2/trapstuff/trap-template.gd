#we need to look into trap placement
#tile gen
extends Entity
class_name Trap

@export var action_array: Array[Action]
var action_count: int = action_max
@export var action_max: int = 1
@onready var action_decoder = get_tree().get_first_node_in_group("ActionDecoder")
@export_subgroup("Base Trap Values")
@export var vision_dist: int = 5
@export var map_manager: MapManager

signal activation(trap: Trap)
signal destroyed(trap: Trap)
signal dismantled(trap: Trap)

var has_activated: bool = false
var is_functional: bool = true
signal trap_ready(trap: Trap, global_pos: Vector2)


func _ready() -> void:
	call_deferred("_setup_trap")
	var manager = get_tree().get_first_node_in_group("TrapManager")

	if manager:
		manager.add_trap(self, map_manager.get_tile_from_pos(global_position))
	ready_entity()
	add_to_group("Trap")
	connect("health_changed", Callable(self, "_on_health_changed"))
	await get_tree().process_frame
	call_deferred("_assign_action_decoder")
	emit_signal("trap_ready", self, global_position)  #new


func _assign_action_decoder() -> void:
	if action_decoder == null:
		# Look directly under root for ActionDecoder
		#var decoder = get_tree().get_root().find_child("ActionDecoder", true, false)
		var manager = get_tree().get_first_node_in_group("TrapManager")
		#if decoder:
		if manager:
			action_decoder = manager.action_decoder
		#	action_decoder = decoder
			print("[Trap] Found ActionDecoder under root:", manager)
		else:
			push_warning("[Trap] Could not find ActionDecoder under root!")


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

func refresh_actions():
	has_activated = false
	action_count = action_max 

func on_activate(_body: Node = null) -> void:
	pass
